// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IBaseService
/// @notice This interface is shared between L1 and L2 contracts to receive notifications about slashings, stake changes and operator withdrawals.
interface IBaseService {
    /// @notice This function is called when a delegator's stake changes.
    /// @param operator The address of the operator.
    /// @param newBalance The new balance of the operator.
    /// @param delegator The address of the delegator.
    /// @param newDelegatorStake The new stake of the delegator.
    function reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
        external;

    /// @notice This function is called when an operator is slashed.
    /// @param operator The address of the operator.
    /// @param remainingPercentage The remaining percentage of the operator's stake.
    function reportOperatorSlash(address operator, uint256 remainingPercentage) external;

    /// @notice This function is called when an operator ERC-721 token is transferred away from the service contract.
    /// @param operator The address of the operator.
    function onWithdrawal(address operator) external;
}
