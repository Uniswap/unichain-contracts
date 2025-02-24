// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IFeeSplitter} from '../../interfaces/FeeSplitter/IFeeSplitter.sol';
import {INetFeeSplitter} from '../../interfaces/FeeSplitter/INetFeeSplitter.sol';
import {IRewardDistributor} from '../../interfaces/UVN/L2/IRewardDistributor.sol';
import {RewardDistributorParams} from './RewardDistributorParams.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';

import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import {console2} from 'forge-std/console2.sol';

contract RewardDistributor is RewardDistributorParams, IRewardDistributor {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IFeeSplitter private immutable FEE_SPLITTER;
    INetFeeSplitter private immutable NET_FEE_SPLITTER;
    IVotes private immutable L2_STAKE_MANAGER;

    struct Window {
        uint256 endBlockNumber;
        uint256 reward;
        uint256 totalSupply;
        bytes32 blockHash;
        bytes32 mostVotedBlockHash;
        bytes32 mostVotedHash;
        uint256 mostVotedHashVotes;
        uint256 nextWindowBlockNumber;
        mapping(bytes32 hash => uint256 votes) attestations;
    }

    struct Attestation {
        bytes32 votedHash;
        uint256 votes;
        uint256 next;
    }

    struct Attestations {
        uint256 head;
        uint256 tail;
        mapping(uint256 blockNumber => Attestation) attestations;
    }

    uint256 private _windowFinalizationPointer;
    uint256[] private _windowBlockNumbers;
    mapping(uint256 blockNumber => Window window) private _windows;
    mapping(address operator => Attestations attestations) private _attestations;

    constructor(
        address admin,
        address feeSplitter,
        address l2StakeManager,
        uint256 attestationWindowLength_,
        uint256 attestationPeriod_
    ) RewardDistributorParams(admin, attestationWindowLength_, attestationPeriod_) {
        FEE_SPLITTER = IFeeSplitter(feeSplitter);
        NET_FEE_SPLITTER = INetFeeSplitter(FEE_SPLITTER.NET_FEE_RECIPIENT());
        L2_STAKE_MANAGER = IVotes(l2StakeManager);
        uint256 blockNumber = block.number - 1;
        _windows[blockNumber].endBlockNumber = blockNumber;
        _windows[blockNumber].nextWindowBlockNumber = blockNumber + attestationWindowLength();
        _windows[blockNumber].blockHash = blockhash(blockNumber);
        _windowBlockNumbers.push(0);
        _windowBlockNumbers.push(blockNumber);
        emit AttestationWindowScheduled(blockNumber, blockNumber + attestationWindowLength(), 0);
        _windows[blockNumber].totalSupply = L2_STAKE_MANAGER.getPastTotalSupply(blockNumber);
    }

    receive() external payable {
        if (msg.sender != address(NET_FEE_SPLITTER)) revert InvalidSender();
    }

    /// @notice Attest to a window of blocks
    /// @dev The window is always identified by the block number of the last block in the window
    /// @dev The additional data has to match the data of other operators to be able to reach consensus
    /// @param blockNumber The block number of the last block in the window
    /// @param blockHash The block hash of the last block in the window
    /// @param additionalData Additional data to include in the attestation
    /// @param signature The signature of the operator
    function attest(uint256 blockNumber, bytes32 blockHash, bytes memory additionalData, bytes memory signature)
        external
    {
        if (blockNumber >= block.number) revert NoBlockHashAvailable();
        if (blockNumber < block.number - attestationPeriod()) revert AttestationPeriodPassed();

        bytes32 votedHash = keccak256(abi.encode(blockNumber, blockHash, additionalData)).toEthSignedMessageHash();
        address operator = votedHash.recover(signature);

        Attestations storage a = _attestations[operator];

        // uh oh I hope you aren't double signing
        if (a.attestations[blockNumber].votedHash != bytes32(0)) revert BlockAlreadyAttested();
        if (block.number > _nextWindow()) _scheduleNextWindow();

        // 1. store the attestation
        uint256 votes = L2_STAKE_MANAGER.getPastVotes(operator, blockNumber);
        a.attestations[blockNumber] = Attestation({votedHash: votedHash, votes: votes, next: 0});

        a.attestations[a.tail].next = blockNumber;
        a.tail = blockNumber;

        // 2. keep track of what most voted hash is (including and excluding additional data)
        Window storage window = _windows[blockNumber];
        if (window.nextWindowBlockNumber == 0) revert WindowNotFound();
        window.attestations[votedHash] += votes;
        uint256 votesForHash = window.attestations[votedHash];
        if (votesForHash > window.mostVotedHashVotes) {
            window.mostVotedBlockHash = blockHash;
            window.mostVotedHash = votedHash;
            window.mostVotedHashVotes = votesForHash;
        }

        // 3. process rewards for previously attested windows
        _processRewards(operator);

        emit Attested(operator, blockNumber, votedHash);
    }

    /// @dev The first attestation to the current window will schedule the next window. Windows are scheduled every `attestationWindowLength` blocks. If there are no attestations during the current window, the next window is not scheduled. In this case the current window will be extended until the next attestation occurs. After this, the next window will be scheduled automatically in the same interval again.
    function _scheduleNextWindow() private {
        FEE_SPLITTER.distributeFees();
        uint256 reward = NET_FEE_SPLITTER.withdrawFees(address(this));
        if (reward == 0) revert NoRewardsAvailable();

        Window storage latestWindow = _windows[_windowBlockNumbers[_windowBlockNumbers.length - 1]];
        uint256 nextWindow = latestWindow.nextWindowBlockNumber;
        uint256 attestationWindowLength_ = attestationWindowLength();
        if (block.number - nextWindow > attestationWindowLength_) {
            // entire window has not received any attestations
            // extend the current window
            emit AttestationWindowExtended(nextWindow, block.number - 1);
            nextWindow = block.number - 1;
            latestWindow.nextWindowBlockNumber = nextWindow;
        }

        _windows[nextWindow].reward = reward;
        bytes32 blockHash = blockhash(nextWindow);
        // safe guard, returns 0 for older than 256 blocks, should not happen because of the check when setting the attestation window length
        assert(blockHash != bytes32(0));
        _windows[nextWindow].blockHash = blockHash;
        _windows[nextWindow].endBlockNumber = nextWindow;
        _windows[nextWindow].nextWindowBlockNumber = nextWindow + attestationWindowLength_;
        _windows[nextWindow].totalSupply = L2_STAKE_MANAGER.getPastTotalSupply(nextWindow);
        _windowBlockNumbers.push(nextWindow);
        emit AttestationWindowScheduled(nextWindow, nextWindow + attestationWindowLength_, reward);
    }

    function _processRewards(address operator) private {
        // TODO: implement
    }

    function _nextWindow() internal view returns (uint256) {
        return _windows[_windowBlockNumbers[_windowBlockNumbers.length - 1]].nextWindowBlockNumber;
    }
}
