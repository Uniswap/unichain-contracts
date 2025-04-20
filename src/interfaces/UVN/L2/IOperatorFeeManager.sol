// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IOperatorFeeManager - Interface for the OperatorFeeManager
/// @notice Contracts implementing this interface can be used to calculate the operator fee for a given reward received by delegators
/// @dev Must implement the receive function to receive the operator fee
interface IOperatorFeeManager {
    /// @notice Calculates the operator fee for a given reward
    /// @param reward The reward received by delegators
    /// @return fee The operator fee taken from the reward
    function operatorFee(uint256 reward) external view returns (uint256 fee);
}
