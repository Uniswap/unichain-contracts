// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProtocolRewardDistributor} from './IProtocolRewardDistributor.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';

/// @title OperatorManager - Base contract for the StakingMiddleware
/// @notice This contract manages the selection of operators by delegators. The selection of operators implements the `IVotes` interface. Before a delegator can undelegate from an operator, they must pass a delay period. During this delay period their voting power is set to 0 but they remain slashable until the undelegation is finalized.
interface IOperatorManager is IProtocolRewardDistributor, IVotes {
    /// @notice Emitted when an operator is slashed
    event OperatorSlashed(address indexed operator, uint96 remainingPercentage);

    /// @notice Emitted when a delegator announces their intention to undelegate from their current operator
    event OperatorUndelegationAnnounced(address indexed delegator, address indexed operator, uint256 timestamp);

    /// @notice Thrown when a delegator attempts to delegate to another operator while already delegating to one or having a pending undelegation
    error AlreadyDelegated();

    /// @notice Thrown when a delegator attempts to undelegate from an operator while not delegating to one
    error NotDelegated();

    /// @notice Thrown when a delegator attempts to undelegate from an operator without announcing their intention to undelegate first
    error AnnounceUndelegationFirst();

    /// @notice Thrown when a delegator attempts to undelegate from an operator while the undelegation is not finalized
    error UndelegationNotFinalized(uint256 timestamp);

    /// @notice Announces the intention to undelegate from the current operator
    /// @dev The user can finalize their undelegation after the undelegation delay has passed by calling `delegate` with `address(0)` as the argument
    /// @dev The user remains slashable until the undelegation is finalized
    function announceOperatorUndelegation() external;

    /// @notice Returns the slashable stake of an operator (the sum of all delegator stakes that are delegated to it and their pending withdrawals)
    function slashableOperatorStake(address operator) external view returns (uint96);
}
