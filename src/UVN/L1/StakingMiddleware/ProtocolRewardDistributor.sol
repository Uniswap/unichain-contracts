// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IProtocolRewardDistributor} from '../../../interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol';
import {IUniStaker, UniStakerWrapper} from './UniStakerWrapper.sol';

/// @title ProtocolRewardDistributor - Base contract for the StakingMiddleware
/// @notice This contract distributes accrued protocol fees to delegators that have opted into depositing their underlying UNI stake into the UniStaker contract.
abstract contract ProtocolRewardDistributor is UniStakerWrapper, IProtocolRewardDistributor {
    uint256 private constant PRECISION = 1e27;
    uint256 internal _globalRewardCheckpoint;
    mapping(address account => uint256 checkpoint) internal _rewardCheckpointOf;
    mapping(address account => uint256 earnedRewards) internal _earnedRewardsOf;

    /// @dev before a delegator stakes, claim rewards with the balance prior to the deposit
    function _beforeStake(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeStake(delegator, amount);
    }

    /// @dev before a delegator withdraws, claim rewards with the balance prior to the withdrawal
    function _beforeWithdraw(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeWithdraw(delegator, amount);
    }

    /// @dev before a delegator deposits into the UniStaker contract, update their checkpoint to ensure correct reward distribution
    function _beforeUniStakerDeposit(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeUniStakerDeposit(delegator, amount);
    }

    /// @dev before a delegator withdraws from the UniStaker contract, claim rewards with the balance prior to the withdrawal
    function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeUniStakerWithdrawal(delegator, amount);
    }

    /// @inheritdoc IProtocolRewardDistributor
    function withdrawRewards(address to) public virtual returns (uint256 reward) {
        _beforeRewardsWithdrawal(msg.sender);
        _updateRewardCheckpoint(msg.sender);
        reward = _earnedRewardsOf[msg.sender];
        if (reward != 0) {
            _earnedRewardsOf[msg.sender] = 0;
            REWARD_TOKEN.transfer(to, reward);
            emit RewardsWithdrawn(msg.sender, to, reward);
        }
        return reward;
    }

    /// @inheritdoc IProtocolRewardDistributor
    function rewardsOf(address account) public view virtual returns (uint256) {
        uint256 unclaimedGlobalReward = UNISTAKER.unclaimedReward(address(this));
        uint256 globalCheckpoint = _getNewGlobalRewardCheckpoint(unclaimedGlobalReward);
        return _earnedRewardsOf[account] + _calculateRewardUntil(account, globalCheckpoint);
    }

    /// @dev claims rewards from the UniStaker contract for all delegators
    function _updateGlobalRewardCheckpoint() internal returns (uint256 newGlobalRewardCheckpoint) {
        uint256 reward;
        try UNISTAKER.claimReward() returns (uint256 newReward) {
            // @audit a malicious reward notifier in the unistaker contract could brick deposits and withdrawals
            reward = newReward;
        } catch {}
        // @audit if total amount staked is 0, reward will also be 0
        if (reward == 0) return _globalRewardCheckpoint;
        newGlobalRewardCheckpoint = _getNewGlobalRewardCheckpoint(reward);
        _globalRewardCheckpoint = newGlobalRewardCheckpoint;
        emit RewardsAdded(reward);
    }

    function _updateRewardCheckpoint(address account) internal {
        uint256 newRewardCheckpoint = _updateGlobalRewardCheckpoint();
        _distributeRewards(account, _calculateRewardUntil(account, newRewardCheckpoint), newRewardCheckpoint);
    }

    /// @dev Distributes rewards to a delegator and updates their reward checkpoint
    function _distributeRewards(address account, uint256 reward, uint256 newCheckpoint) internal {
        _earnedRewardsOf[account] += reward;
        _rewardCheckpointOf[account] = newCheckpoint;
        emit RewardDistributed(account, reward);
    }

    /// @dev Calculates the new global reward checkpoint based on a new reward amount
    function _getNewGlobalRewardCheckpoint(uint256 reward) internal view returns (uint256) {
        return _globalRewardCheckpoint + (reward * PRECISION) / _totalAmountDepositedIntoUniStaker();
    }

    /// @dev Calculates the rewards a delegator has earned up to a given checkpoint
    function _calculateRewardUntil(address account, uint256 checkpoint) internal view returns (uint256) {
        return _calculateRewardFromTo(_stakedBalanceOf(account), _rewardCheckpointOf[account], checkpoint);
    }

    /// @dev Calculates the rewards a balance earns between two checkpoints
    function _calculateRewardFromTo(uint256 balance, uint256 from, uint256 to) internal pure returns (uint256) {
        return (balance * (to - from)) / PRECISION;
    }

    function _beforeRewardsWithdrawal(address delegator) internal virtual {}
}
