// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/universal/FeeVault.sol
interface IFeeVault {
    /// @notice Enum representing where the FeeVault withdraws funds to.
    /// @custom:value L1 FeeVault withdraws funds to L1.
    /// @custom:value L2 FeeVault withdraws funds to L2.
    enum WithdrawalNetwork {
        L1,
        L2
    }
    
    /// @notice Network which the recipient will receive fees on.
    ///         Use the `withdrawalNetwork()` getter as this is deprecated
    ///         and is subject to be removed in the future.
    /// @custom:legacy
    function WITHDRAWAL_NETWORK() external view returns (WithdrawalNetwork);
    function withdrawalNetwork() external view returns (WithdrawalNetwork);

    /// @notice Account that will receive the fees. Can be located on L1 or L2.
    ///         Use the `recipient()` getter as this is deprecated
    ///         and is subject to be removed in the future.
    /// @custom:legacy
    function RECIPIENT() external view returns (address);
    function recipient() external view returns (address);

    /// @notice Minimum balance before a withdrawal can be triggered.
    ///         Use the `minWithdrawalAmount()` getter as this is deprecated
    ///         and is subject to be removed in the future.
    /// @custom:legacy
    function MIN_WITHDRAWAL_AMOUNT() external view returns (uint256);
    function minWithdrawalAmount() external view returns (uint256);

    /// @notice Triggers a withdrawal of funds to the fee wallet on L1 or L2.
    function withdraw() external;
}