// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IProtocolRewardDistributor} from './IProtocolRewardDistributor.sol';

interface IOperatorManager is IProtocolRewardDistributor {
    /// @notice Emitted when a delegator announces their intention to undelegate from their current operator
    event OperatorUndelegationAnnounced(address indexed delegator, address indexed operator, uint256 timestamp);

    /// @notice Thrown when a delegator attempts to delegate to another operator while already delegating to one
    error OperatorAlreadySelected();

    /// @notice Thrown when a delegator attempts to undelegate from an operator while not delegating to one
    error NoOperatorSelected();

    /// @notice Thrown when a delegator attempts to undelegate from an operator while the undelegation is not finalized
    error UndelegationNotFinalized(uint256 timestamp);

    /// @notice Announces the intention to undelegate from the current operator
    /// @dev The user can finalize their undelegation after the undelegation delay has passed by calling `delegate` with `address(0)` as the argument
    /// @dev The user remains slashable until the undelegation is finalized
    function announceOperatorUndelegation() external;

    /// @notice Returns the slashable stake of an operator (the sum of all delegator stakes that are delegated to it and their pending withdrawals)
    function slashableOperatorStake(address operator) external view returns (uint96);
}
