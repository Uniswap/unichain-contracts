// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDelegatorAccessControl} from './IDelegatorAccessControl.sol';

/// @title SlashingManager - Base contract for the StakingMiddleware
/// @notice This contract manages the slashing of delegators and operators. When operators are slashed, the slashed amount is converted into the remaining percentage of the operator's slashable delegated stake. The voting power of the operator is updated immediately. As delegators have their own deposits into the UniStaker contract, slashing is applied to the delegator's slashable stake when the delegator next interacts with the StakingMiddleware contract. Slashing can also be applied by anyone at any time. To ensure there isn't an incentive to not stay slashed and continue accruing protocol fees in the UniStaker contract, rewards accrued by the delegator are also slashed.
interface ISlashingManager is IDelegatorAccessControl {
    /// @notice Thrown when an attempt is made to slash zero stake
    error SlashingAmountZero();
    /// @notice Thrown when a slashing percentage exceeds 100%
    error SlashingPercentageTooHigh();
    /// @notice When the zero address is slashed
    error AddressZero();

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

    /// @notice Returns the role for slashers
    function SLASHER_ROLE() external view returns (bytes32);
}
