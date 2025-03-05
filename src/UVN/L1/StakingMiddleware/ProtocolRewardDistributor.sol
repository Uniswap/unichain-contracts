// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IProtocolRewardDistributor} from '../../../interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol';
import {IUniStaker, UniStakerWrapper} from './UniStakerWrapper.sol';

abstract contract ProtocolRewardDistributor is UniStakerWrapper, IProtocolRewardDistributor {
    uint256 private constant PRECISION = 1e27;
    uint256 private _globalRewardCheckpoint;
    mapping(address account => uint256 checkpoint) private _rewardCheckpointOf;
    mapping(address account => uint256 earnedRewards) private _earnedRewardsOf;

    function withdrawRewards(address to) external returns (uint256 reward) {
        _updateRewardCheckpoint(msg.sender);
        reward = _earnedRewardsOf[msg.sender];
        if (reward != 0) {
            _earnedRewardsOf[msg.sender] = 0;
            rewardToken.transfer(to, reward);
            emit RewardsWithdrawn(msg.sender, to, reward);
        }
        return reward;
    }

    function rewardsOf(address account) public view returns (uint256) {
        return _earnedRewardsOf[account] + _calculateRewardSinceLastCheckpoint(account);
    }

    function _updateRewardIndex() internal {
        // @audit a malicious reward notifier in the unistaker contract could brick deposits and withdrawals
        uint256 reward = unistaker.claimReward();
        // @audit if total amount staked is 0, reward will also be 0
        if (reward == 0) return;
        _globalRewardCheckpoint += (reward * PRECISION) / _totalAmountStaked();
        emit RewardsAdded(reward);
    }

    function _updateRewardCheckpoint(address account) internal {
        _updateRewardIndex();
        _earnedRewardsOf[account] += _calculateRewardSinceLastCheckpoint(account);
        _rewardCheckpointOf[account] = _globalRewardCheckpoint;
    }

    function _calculateRewardSinceLastCheckpoint(address account) internal view returns (uint256) {
        return (_stakedBalanceOf(account) * (_globalRewardCheckpoint - _rewardCheckpointOf[account])) / PRECISION;
    }
}
