// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IService} from './IService.sol';

/// @title IStakeTableSync
/// @notice This contract is used to sync the stake table of the StakingMiddleware contract to the L2. On notifications about slashing and balance changes from the StakingMiddleware, the data is forwarded to the StakeTable contract on L2. On deposits of operator ERC-721 tokens, the initial balance of the operator is reported to the StakeTable contract on L2. Should an operator already have delegators before depositing their operator token or should they withdraw their operator token and re-deposit it, inconsistencies in the stake of individual delegators could occur. This contract exposes two sync functions to forcefully sync the correct balances to L2.
interface IStakeTableSync is IService {
    /// @notice Thrown when the `IService` functions are called by an account other than the StakingMiddleware
    error NotStakingMiddleware();

    /// @notice Syncs the current stake of a delegator and their operator to L2
    /// @dev This function can be called to sync inconsistencies in the stake table
    /// @dev Callable by anyone
    function sync(address delegator) external;

    /// @notice Syncs the current total delegated stake of an operator to L2
    /// @dev This function can be called to sync inconsistencies in the stake table
    /// @dev Callable by anyone
    function syncOperator(address operator) external;
}
