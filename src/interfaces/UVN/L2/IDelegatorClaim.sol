// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDelegatorClaim - An interface for contracts that handle delegator rewards
/// @notice This interface is used for delegator reward distribution. Operators can override the default delegator claim contract with a custom contract that implements this interface.
interface IDelegatorClaim {
    /// @notice Reports a delegator stake to the reward distributor contract
    /// @param delegator The address of the delegator
    /// @param newStake The new stake of the delegator
    /// @dev MUST revert if the caller is not the L2 stake table sync contract
    /// @dev When an operator is slashed, delegator stakes are only updated when slashing is applied on L1
    function reportDelegatorStake(address delegator, uint256 newStake) external;
}
