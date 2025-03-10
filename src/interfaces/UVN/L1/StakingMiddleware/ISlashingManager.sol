// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IOperatorManager} from './IOperatorManager.sol';

interface ISlashingManager {
    error SlashingAmountZero();
    error SlashingPercentageTooHigh();

    /// @notice Emitted when a delegator's stake is slashed
    event OperatorSlashed(address indexed operator, uint256 remainingPercentage);

    /// @notice Slashes a delegator's stake by a specific amount
    function slashAmount(address operator, uint96 amount) external;

    /// @notice Slashes a delegator's stake by a percentage of the total stake
    function slashPercentage(address operator, uint96 percentage) external;

    /// @notice Applies pending slashing to a delegator's stake
    function applySlashing(address delegator, uint256 n) external;

    /// @notice Returns whether a delegator's stake is slashed and is pending for finalization
    function slashingPendingForDelegator(address delegator) external view returns (bool);
}
