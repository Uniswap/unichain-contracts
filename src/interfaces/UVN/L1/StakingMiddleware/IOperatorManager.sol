// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IProtocolRewardDistributor} from './IProtocolRewardDistributor.sol';

interface IOperatorManager is IProtocolRewardDistributor {
    /// @notice Thrown when a delegator attempts to delegate to another operator while already delegating to one
    error OperatorAlreadySelected();

    /// @notice Thrown when a delegator attempts to undelegate from an operator while not delegating to one
    error NoOperatorSelected();
}
