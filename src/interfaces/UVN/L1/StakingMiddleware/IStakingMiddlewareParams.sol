// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IStakingMiddlewareParams {
    event WithdrawalDelayUpdated(uint256 oldWithdrawalDelay, uint256 newWithdrawalDelay);
    event SlashingBeneficiaryUpdated(address oldSlashingBeneficiary, address newSlashingBeneficiary);

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
