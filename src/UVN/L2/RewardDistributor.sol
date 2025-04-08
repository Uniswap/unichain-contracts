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
import {Window, WindowLib, Windows} from './libraries/WindowLib.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';

/// @title RewardDistributor
/// @notice Distributes rewards to operators based on their attestations. Operators attest to a group of blocks (windows). Whenever a window is finalized, the reward is distributed to the operators that voted together with the majority of the votes.
/// @dev To guarantee the correct allocation of rewards to windows, should no attestations be made to a window, the scheduled window is extended to the previous block before it activates.
contract RewardDistributor is RewardDistributorParams, IRewardDistributor {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev 2/3rd of the total supply need to attest to a block for it to be finalized
    uint256 private constant SUCCESSFUL_ATTESTATION_PERCENTAGE = 666_666_666_666_666_667;
    uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
    IStakeTable private immutable L2_STAKE_MANAGER;

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
        uint256 votingSupply = L2_STAKE_MANAGER.getPastTotalSupply(blockNumber);
        uint256 newScheduledWindow = _windows.activate(blockNumber, 0, votingSupply);
        emit AttestationWindowActivated(blockNumber, newScheduledWindow);
    }

    /// @dev contract can receive rewards by either pulling from the rewardPuller or by being sent ETH directly to this contract
    receive() external payable {
        uint256 scheduledWindowBlockNumber = _windows.recordReward(msg.value);
        emit RewardReceived(scheduledWindowBlockNumber, msg.value);
        if (block.number > scheduledWindowBlockNumber) {
            _activateScheduledWindow();
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
        if (_window(blockNumber).isFinalized()) revert WindowAlreadyFinalized();
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
        _windows.attest(blockNumber, blockHash, votedHash, votes);

        // 3. process rewards for previously attested windows
        _processRewards(operator);

        emit Attested(operator, blockNumber, graffiti, votedHash);
    }

    /// @inheritdoc IRewardDistributor
    function status(uint256 targetBlockNumber) public view returns (Status) {
        (uint256 window, bool exists) = _windows.find(targetBlockNumber);
        return _status(targetBlockNumber, window, exists);
    }

    /// @inheritdoc IRewardDistributor
    function attestationResult(uint256 targetBlockNumber) external view returns (AttestationResult) {
        (uint256 windowBlockNumber, bool exists) = _windows.find(targetBlockNumber);
        Status status_ = _status(targetBlockNumber, windowBlockNumber, exists);
        if (status_ == Status.Active || status_ == Status.Finalized) {
            // window is active with no attestations
            if (!exists) return AttestationResult.Pending;
            // window is active with sufficient attestations
            Window storage window = _window(windowBlockNumber);
            if (
                window.mostVotedHashVotes
                    > window.votingTotalSupply * SUCCESSFUL_ATTESTATION_PERCENTAGE / PERCENTAGE_DENOMINATOR
            ) {
                return
                    window.mostVotedBlockHash == window.blockHash ? AttestationResult.Valid : AttestationResult.Invalid;
            }
            return _acceptingAttestations(windowBlockNumber)
                ? AttestationResult.Pending
                : AttestationResult.InsufficientVotes;
        }
        return AttestationResult.Pending;
    }

    /// @inheritdoc IRewardDistributor
    function latestActiveWindow() external view returns (uint256) {
        // @audit invariant: there is always at least one active window an operator can attest to
        Window storage currentWindow = _windows.current();
        uint256 nextWindowEnd = currentWindow.nextWindow.blockNumber();
        // a window is scheduled, the latest active window is in storage
        if (block.number < nextWindowEnd) return _windows.currentBlockNumber();
        // the window is pending, activate the scheduled window
        if (block.number < nextWindowEnd + attestationWindowLength()) return nextWindowEnd;
        // a window is delayed, the active window is extended to the last block
        return _activeWindowEndAfterDelay(nextWindowEnd);
    }

    /// @dev The first attestation after the scheduled window has passed will activate the scheduled window. If there are no attestations to this window after `attestationLength` blocks, the window will start extending until this function is called on the first attestation or reward distribution.
    function _activateScheduledWindow() private {
        Window storage lastActiveWindow = _windows.current();
        (uint256 scheduledWindow, uint256 reward) = lastActiveWindow.nextWindow.get();
        if (_windows.isNextWindowDelayed()) {
            // entire window has not received any attestations
            // extend the current window
            uint256 activeWindowEnd = _activeWindowEndAfterDelay(scheduledWindow);
            emit AttestationWindowExtended(scheduledWindow, activeWindowEnd);
            lastActiveWindow.extendScheduledWindow();
            scheduledWindow = activeWindowEnd;
        }
        uint256 votingSupply = L2_STAKE_MANAGER.getPastTotalSupply(scheduledWindow);
        uint256 newScheduledWindow = _windows.activate(scheduledWindow, reward, votingSupply);
        emit AttestationWindowActivated(scheduledWindow, newScheduledWindow);
    }

    function _processRewards(address operator) private {
        Attestations storage attestations = _attestations[operator];
        uint256 blockNumber = attestations.nextBlockNumber();
        assert(blockNumber != 0);
        _finalizeWindow(blockNumber);
        Window storage window = _window(blockNumber);
        if (!window.isFinalized()) return;
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
        Window storage window = _window(blockNumber);
        if (window.isFinalized() || _acceptingAttestations(blockNumber)) return;
        window.finalized = true;
        uint256 totalSupply = window.votingTotalSupply;
        uint256 attestationRatio =
            totalSupply == 0 ? 0 : window.mostVotedHashVotes * PERCENTAGE_DENOMINATOR / totalSupply;
        uint256 reward = window.rewardETH;
        uint256 rewardsToDistribute = reward * attestationRatio / PERCENTAGE_DENOMINATOR;
        uint256 unclaimedRewards = reward - rewardsToDistribute;
        window.rewardETH = uint96(rewardsToDistribute);
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

    function _status(uint256 targetBlockNumber, uint256 windowBlockNumber, bool exists) private view returns (Status) {
        if (exists) {
            // window found, must be active or finalized
            // window finalizes after the attestation period has passed
            if (!_acceptingAttestations(windowBlockNumber)) {
                return Status.Finalized;
            }
            return Status.Active;
        }
        Window storage currentWindow = _windows.current();
        uint256 scheduledWindowEnd = currentWindow.nextWindow.blockNumber();
        uint256 attestationWindowLength_ = attestationWindowLength();
        if (block.number > scheduledWindowEnd + attestationWindowLength_) {
            // no attestations during the pending window were made, thus the next window could not be scheduled. Extend the current window until the next attestation occurs.
            uint256 activeWindowEnd = _activeWindowEndAfterDelay(scheduledWindowEnd);
            if (targetBlockNumber <= activeWindowEnd) return Status.Active;
            if (targetBlockNumber <= activeWindowEnd + attestationWindowLength_) return Status.Delayed;
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

    /// @dev When a window is delayed, the active window is extended in increments of `attestationWindowLength` blocks. This function returns the last block of the active window after a delay.
    function _activeWindowEndAfterDelay(uint256 nextWindowEnd) private view returns (uint256) {
        uint256 attestationWindowLength_ = attestationWindowLength();
        uint256 blocksUntilNextWindow = (block.number - nextWindowEnd) % attestationWindowLength_;
        // if the current block is exactly the next block to attest, still point to the last window
        if (blocksUntilNextWindow == 0) blocksUntilNextWindow = attestationWindowLength_;
        return block.number - blocksUntilNextWindow;
    }
}
