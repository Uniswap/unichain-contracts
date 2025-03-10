// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IProtocolRewardDistributor} from '../../../interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol';
import {IUniStaker, UniStakerWrapper} from './UniStakerWrapper.sol';

abstract contract ProtocolRewardDistributor is UniStakerWrapper, IProtocolRewardDistributor {
    uint256 private constant PRECISION = 1e27;
    uint256 internal _globalRewardCheckpoint;
    mapping(address account => uint256 checkpoint) internal _rewardCheckpointOf;
    mapping(address account => uint256 earnedRewards) internal _earnedRewardsOf;

    function _beforeDeposit(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeDeposit(delegator, amount);
    }

    function _beforeWithdrawal(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeWithdrawal(delegator, amount);
    }

    function _beforeUniStakerDeposit(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeUniStakerDeposit(delegator, amount);
    }

    function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal virtual override {
        _updateRewardCheckpoint(delegator);
        super._beforeUniStakerWithdrawal(delegator, amount);
    }

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

    function rewardsOf(address account) public view virtual returns (uint256) {
        uint256 unclaimedGlobalReward = UNISTAKER.unclaimedReward(address(this));
        uint256 globalCheckpoint = _getNewGlobalRewardCheckpoint(unclaimedGlobalReward);
        return _earnedRewardsOf[account] + _calculateRewardUntil(account, globalCheckpoint);
    }

    function _updateGlobalRewardCheckpoint() internal returns (uint256 newGlobalRewardCheckpoint) {
        // @audit a malicious reward notifier in the unistaker contract could brick deposits and withdrawals
        // @audit no need for safe cast as WETH reward cannot exceed 2^120
        uint256 reward = UNISTAKER.claimReward();
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

    function _distributeRewards(address account, uint256 reward, uint256 newCheckpoint) internal {
        _earnedRewardsOf[account] += reward;
        _rewardCheckpointOf[account] = newCheckpoint;
        emit RewardDistributed(account, reward);
    }

    function _getNewGlobalRewardCheckpoint(uint256 reward) internal view returns (uint256) {
        return _globalRewardCheckpoint + (reward * PRECISION) / _totalAmountStaked();
    }

    function _calculateRewardUntil(address account, uint256 checkpoint) internal view returns (uint256) {
        return _calculateRewardFromTo(_stakedBalanceOf(account), _rewardCheckpointOf[account], checkpoint);
    }

    function _calculateRewardFromTo(uint256 balance, uint256 from, uint256 to) internal pure returns (uint256) {
        return (balance * (to - from)) / PRECISION;
    }

    function _beforeRewardsWithdrawal(address delegator) internal virtual {}
}
