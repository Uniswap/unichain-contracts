// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';

/// @title StakingMiddlewareParams - Base contract for the StakingMiddleware
/// @notice This contract manages the parameters of the StakingMiddleware contract. It allows roles to set the withdrawal delay and the slashing beneficiary.
interface IStakingMiddlewareParams is IAccessControl {
    /// @notice Emitted when the withdrawal delay is updated
    event WithdrawalDelayUpdated(uint256 indexed oldWithdrawalDelay, uint256 indexed newWithdrawalDelay);
    /// @notice Emitted when the slashing beneficiary is updated
    event SlashingBeneficiaryUpdated(address indexed oldSlashingBeneficiary, address indexed newSlashingBeneficiary);

    /// @notice Thrown when the withdrawal delay is set to a value greater than the maximum allowed
    error InvalidWithdrawalDelay();

    /// @notice Updates the withdrawal delay
    /// @param withdrawalDelay The new withdrawal delay in seconds
    function updateWithdrawalDelay(uint256 withdrawalDelay) external;

    /// @notice Updates the slashing beneficiary that receives slashed stake and rewards
    /// @param slashingBeneficiary The new slashing beneficiary
    function updateSlashingBeneficiary(address slashingBeneficiary) external;

    /// @notice The delay before a user can withdraw their stake or change their operator
    /// @return The withdrawal delay in seconds
    function withdrawalDelay() external view returns (uint256);

    /// @notice The slashing beneficiary that receives slashed stake and rewards
    /// @return The slashing beneficiary
    function slashingBeneficiary() external view returns (address);

    /// @notice The role that can set parameters
    function PARAMS_SETTER_ROLE() external view returns (bytes32);
}
