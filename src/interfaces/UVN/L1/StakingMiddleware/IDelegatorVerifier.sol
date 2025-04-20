// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDelegatorVerifier
/// @notice Interface for a contract that verifies whether a delegator is allowed to delegate to an operator
/// @dev A contract implementing this interface can be deployed by the operator to verify whether a delegator is allowed to delegate to it
interface IDelegatorVerifier {
    /// @notice Returns whether a delegator is allowed to delegate to an operator
    /// @param delegator The address of the delegator
    /// @return allowDelegation Whether the delegator is allowed to delegate to an operator
    function allowDelegation(address delegator) external view returns (bool allowDelegation);
}
