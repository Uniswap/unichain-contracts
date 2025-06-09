// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/// @title IRewardPuller
/// @notice Contracts implementing this interface can be called by the reward distributor automatically to pull new rewards.
interface IRewardPuller is IERC165 {
    /// @notice Pulls rewards from a reward source in ETH and forwards them to the reward distributor contract
    /// @return The amount of rewards pulled
    function pullRewards() external returns (uint256);
}
