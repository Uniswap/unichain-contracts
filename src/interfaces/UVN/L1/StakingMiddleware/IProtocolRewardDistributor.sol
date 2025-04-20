// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniStakerWrapper} from './IUniStakerWrapper.sol';

/// @title ProtocolRewardDistributor - Base contract for the StakingMiddleware
/// @notice This contract distributes accrued protocol fees to delegators that have opted into depositing their underlying UNI stake into the UniStaker contract.
interface IProtocolRewardDistributor is IUniStakerWrapper {
    /// @notice Emitted when protocol rewards are added from the UniStaker contract
    event RewardsAdded(uint256 amount);
    /// @notice Emitted when a user's rewards are distributed
    event RewardDistributed(address indexed account, uint256 amount);
    /// @notice Emitted when a user withdraws their rewards
    event RewardsWithdrawn(address indexed account, address indexed to, uint256 amount);

    /// @notice Withdraws the user's protocol rewards
    /// @param to The address to send the rewards to
    /// @return The amount of protocol rewards withdrawn
    function withdrawRewards(address to) external returns (uint256);

    /// @notice Returns the amount of protocol rewards a user has earned
    /// @param account The address of the user to check
    /// @return The amount of protocol rewards the user has earned
    function rewardsOf(address account) external view returns (uint256);
}
