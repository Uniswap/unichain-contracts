// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IFeeSplitter} from '../../interfaces/FeeSplitter/IFeeSplitter.sol';
import {INetFeeSplitter} from '../../interfaces/FeeSplitter/INetFeeSplitter.sol';
import {IRewardDistributor} from '../../interfaces/UVN/L2/IRewardDistributor.sol';
import {IRewardPuller} from '../../interfaces/UVN/L2/IRewardPuller.sol';
import {IStakeTable} from '../../interfaces/UVN/L2/IStakeTable.sol';
import {RewardDistributorParams} from './RewardDistributorParams.sol';
import {AttestationLib, Attestations} from './libraries/AttestationLib.sol';
import {Search} from './libraries/Search.sol';
import {NextWindow, WindowLib} from './libraries/WindowLib.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';

contract RewardDistributor is RewardDistributorParams, IRewardDistributor {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using Search for uint256[];

    struct Window {
        bool finalized;
        uint256 rewardETH;
        uint256 votingTotalSupply;
        bytes32 blockHash;
        bytes32 mostVotedBlockHash;
        bytes32 mostVotedHash;
        uint256 mostVotedHashVotes;
        NextWindow nextWindow;
        uint256 index;
        mapping(bytes32 votedHash => uint256 votes) attestations;
    }

    /// @dev 2/3rd of the total supply need to attest to a block for it to be finalized
    uint256 private constant SUCCESSFUL_ATTESTATION_PERCENTAGE = 666_666_666_666_666_667;
    uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
    IStakeTable private immutable L2_STAKE_MANAGER;

    uint256 private _windowFinalizationPointer;
    uint256[] private _windowBlockNumbers;
    mapping(uint256 blockNumber => Window window) private _windows;
    mapping(address operator => Attestations attestations) private _attestations;
    uint256 private _lastRewardPayout;

    constructor(
        address admin,
        IStakeTable l2StakeManager,
        IRewardPuller rewardPuller_,
        uint256 attestationWindowLength_,
        uint256 attestationPeriod_
    ) RewardDistributorParams(admin, attestationWindowLength_, attestationPeriod_, rewardPuller_) {
        L2_STAKE_MANAGER = l2StakeManager;
        uint256 blockNumber = block.number - 1;
        _windows[blockNumber].nextWindow = WindowLib.setNextBlockNumber(blockNumber + attestationWindowLength());
        _windows[blockNumber].blockHash = blockhash(blockNumber);
        _windowBlockNumbers.push(blockNumber);
        emit AttestationWindowScheduled(blockNumber, blockNumber + attestationWindowLength());
        _windows[blockNumber].votingTotalSupply = L2_STAKE_MANAGER.getPastTotalSupply(blockNumber);
    }

    /// @dev contract can receive rewards by either pulling from the rewardPuller or by being sent ETH directly to this contract
    receive() external payable {
        Window storage currentWindow = _currentWindow();
        (uint256 nextWindow, uint256 reward) = currentWindow.nextWindow.decode();
        currentWindow.nextWindow = WindowLib.encode(nextWindow, reward + msg.value);
        emit RewardReceived(nextWindow, msg.value);
        if (block.number > nextWindow) {
            _scheduleNextWindow();
        }
    }

    /// @inheritdoc IRewardDistributor
    function attest(
        uint256 blockNumber,
        bytes32 blockHash,
        bytes memory additionalData,
        bytes memory signature,
        bytes32 graffiti
    ) external {
        if (blockNumber >= block.number) revert NoBlockHashAvailable();
        if (_windows[blockNumber].finalized) revert WindowAlreadyFinalized();
        if (!_acceptingAttestations(blockNumber)) revert AttestationPeriodPassed();
        bytes32 votedHash = keccak256(abi.encode(blockNumber, blockHash, additionalData)).toEthSignedMessageHash();
        address operator = votedHash.recover(signature);

        Attestations storage attestations = _attestations[operator];

        if (block.number > _lastRewardPayout) {
            _lastRewardPayout = block.number;
            rewardPuller().pullRewards();
        }

        // 1. store the attestation
        uint256 votes = L2_STAKE_MANAGER.getPastVotes(operator, blockNumber);
        if (votes == 0) revert ZeroVotes();

        attestations.push(blockNumber, votedHash, votes);

        // 2. keep track of what most voted hash is (including and excluding additional data)
        Window storage window = _windows[blockNumber];
        if (window.nextWindow.blockNumber() == 0) revert WindowNotFound();
        window.attestations[votedHash] += votes;
        uint256 votesForHash = window.attestations[votedHash];
        if (votesForHash > window.mostVotedHashVotes) {
            window.mostVotedBlockHash = blockHash;
            window.mostVotedHash = votedHash;
            window.mostVotedHashVotes = votesForHash;
        }

        // 3. process rewards for previously attested windows
        _processRewards(operator);

        emit Attested(operator, blockNumber, graffiti, votedHash);
    }

    /// @inheritdoc IRewardDistributor
    function status(uint256 targetBlockNumber) public view returns (Status) {
        uint256 windowIndex = _findWindowIndex(targetBlockNumber);
        return _status(targetBlockNumber, windowIndex);
    }

    /// @inheritdoc IRewardDistributor
    function attestationResult(uint256 targetBlockNumber) external view returns (AttestationResult) {
        uint256 windowIndex = _findWindowIndex(targetBlockNumber);
        Status s = _status(targetBlockNumber, windowIndex);
        if (s == Status.Active || s == Status.Finalized) {
            // window is active with no attestations
            if (windowIndex == type(uint256).max) return AttestationResult.Pending;
            uint256 windowEnd = _windowBlockNumbers[windowIndex];
            Window storage window = _windows[windowEnd];
            // window is active with sufficient attestations
            if (
                window.mostVotedHashVotes
                    > window.votingTotalSupply * SUCCESSFUL_ATTESTATION_PERCENTAGE / PERCENTAGE_DENOMINATOR
            ) {
                return
                    window.mostVotedBlockHash == window.blockHash ? AttestationResult.Valid : AttestationResult.Invalid;
            }
            return _acceptingAttestations(windowEnd) ? AttestationResult.Pending : AttestationResult.InsufficientVotes;
        }
        return AttestationResult.Pending;
    }

    /// @inheritdoc IRewardDistributor
    function latestActiveWindow() external view returns (uint256) {
        // @audit invariant: there is always at least one active window an operator can attest to
        uint256 currentWindowBlockNumber = _windowBlockNumbers[_windowBlockNumbers.length - 1];
        Window storage currentWindow = _windows[currentWindowBlockNumber];
        uint256 nextWindowEnd = currentWindow.nextWindow.blockNumber();
        // a window is scheduled, the latest active window is in storage
        if (block.number < nextWindowEnd) return currentWindowBlockNumber;
        // the window is pending, activate the scheduled window
        if (block.number < nextWindowEnd + attestationWindowLength()) return nextWindowEnd;
        // a window is delayed, the active window is extended to the last block
        return block.number - 1;
    }

    /// @dev The first attestation to the current window will schedule the next window. Windows are scheduled every `attestationWindowLength` blocks. If there are no attestations during the current window, the next window is not scheduled. In this case the current window will be extended until the next attestation occurs. After this, the next window will be scheduled automatically in the same interval again.
    function _scheduleNextWindow() private {
        Window storage currentWindow = _currentWindow();
        (uint256 nextWindow, uint256 reward) = currentWindow.nextWindow.decode();
        uint256 attestationWindowLength_ = attestationWindowLength();
        if (_windowDelayed(nextWindow, attestationWindowLength_)) {
            // entire window has not received any attestations
            // extend the current window
            emit AttestationWindowExtended(nextWindow, block.number - 1);
            nextWindow = block.number - 1;
            currentWindow.nextWindow = WindowLib.encode(nextWindow, reward);
        }

        _windows[nextWindow].rewardETH = reward;
        bytes32 blockHash = blockhash(nextWindow);
        // @audit safe guard, returns 0 for older than 256 blocks, should not happen because of the check when setting the attestation window length
        assert(blockHash != bytes32(0));
        _windows[nextWindow].blockHash = blockHash;
        _windows[nextWindow].nextWindow = WindowLib.setNextBlockNumber(nextWindow + attestationWindowLength_);
        _windows[nextWindow].votingTotalSupply = L2_STAKE_MANAGER.getPastTotalSupply(nextWindow);
        _windowBlockNumbers.push(nextWindow);
        _windows[nextWindow].index = _windowBlockNumbers.length - 1;
        emit AttestationWindowScheduled(nextWindow, nextWindow + attestationWindowLength_);
    }

    function _processRewards(address operator) private {
        Attestations storage attestations = _attestations[operator];
        uint256 blockNumber = attestations.nextBlockNumber();
        assert(blockNumber != 0);
        _finalizeWindow(blockNumber);
        Window storage window = _windows[blockNumber];
        if (!window.finalized) return;
        (uint256 votes, bytes32 votedHash) = attestations.getVotes(blockNumber);
        attestations.finalize(blockNumber);
        if (votedHash == window.mostVotedHash) {
            address beneficiary = L2_STAKE_MANAGER.beneficiary(operator);
            uint256 rewards = window.rewardETH * votes / window.mostVotedHashVotes;
            (bool success,) = beneficiary.call{value: rewards}('');
            if (!success) revert RewardDistributionFailed();
        }
    }

    function _finalizeWindow(uint256 blockNumber) private {
        Window storage window = _windows[blockNumber];
        if (window.finalized || _acceptingAttestations(blockNumber)) return;
        window.finalized = true;
        uint256 totalSupply = window.votingTotalSupply;
        uint256 attestationRatio =
            totalSupply == 0 ? 0 : window.mostVotedHashVotes * PERCENTAGE_DENOMINATOR / totalSupply;
        uint256 reward = window.rewardETH;
        uint256 rewardsToDistribute = reward * attestationRatio / PERCENTAGE_DENOMINATOR;
        uint256 unclaimedRewards = reward - rewardsToDistribute;
        window.rewardETH = rewardsToDistribute;
        (bool success,) = address(this).call{value: unclaimedRewards}('');
        assert(success);
        AttestationResult result;
        if (SUCCESSFUL_ATTESTATION_PERCENTAGE > attestationRatio) {
            result = AttestationResult.InsufficientVotes;
        } else {
            result = window.mostVotedBlockHash == window.blockHash ? AttestationResult.Valid : AttestationResult.Invalid;
        }
        emit WindowFinalized(blockNumber, result, attestationRatio, rewardsToDistribute);
    }

    function _currentWindow() private view returns (Window storage window) {
        return _windows[_windowBlockNumbers[_windowBlockNumbers.length - 1]];
    }

    function _status(uint256 targetBlockNumber, uint256 windowIndex) private view returns (Status) {
        if (windowIndex != type(uint256).max) {
            // window found, must be active or finalized
            uint256 windowEnd = _windowBlockNumbers[windowIndex];
            // window finalizes after the attestation period has passed
            if (!_acceptingAttestations(windowEnd)) {
                return Status.Finalized;
            }
            return Status.Active;
        }
        Window storage currentWindow = _currentWindow();
        uint256 scheduledWindowEnd = currentWindow.nextWindow.blockNumber();
        uint256 attestationWindowLength_ = attestationWindowLength();
        if (block.number > scheduledWindowEnd + attestationWindowLength_) {
            // no attestations during the pending window were made, thus the next window could not be scheduled. Extend the current window until the next attestation occurs.
            if (targetBlockNumber < block.number) return Status.Active;
            if (targetBlockNumber < block.number + attestationWindowLength_) return Status.Delayed;
            return Status.NonExistent;
        }
        // currently a window is scheduled
        if (targetBlockNumber <= scheduledWindowEnd) {
            // if the scheduled window has passed without any attestations, it becomes active
            return block.number > scheduledWindowEnd ? Status.Active : Status.Scheduled;
        }
        // the window after the scheduled/active window is pending
        if (targetBlockNumber <= scheduledWindowEnd + attestationWindowLength_) return Status.Pending;
        // windows after the pending window do not exist yet
        return Status.NonExistent;
    }

    function _acceptingAttestations(uint256 blockNumber) private view returns (bool) {
        return blockNumber + attestationPeriod() > block.number;
    }

    function _windowDelayed(uint256 windowEnd, uint256 windowLength) private view returns (bool) {
        return block.number > windowLength + windowEnd;
    }

    /// @dev perform an exponential search first to find a range that contains the block number and reduces the search space for recent block numbers
    function _findWindowIndex(uint256 blockNumber) private view returns (uint256) {
        uint256 index = _windows[blockNumber].index;
        // first window has an index of 0, needs to be retrieved via binary search
        if (index != 0) return index;
        (uint256 left, uint256 right) = _windowBlockNumbers.exponentialSearchDesc(blockNumber);
        if (left == right) return left;
        if (right == type(uint256).max) return type(uint256).max;
        return _windowBlockNumbers.binarySearchRoundingUp(blockNumber, left, right);
    }
}
