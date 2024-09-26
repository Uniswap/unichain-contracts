// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IFeeSplitter {
    /// @notice Emitted when `distributeFees` is called and no fees are collected
    event NoFeesCollected();

    /// @notice Emitted when `distributeFees` is called and fees are distributed
    /// @param optimismShare The amount of fees sent to Optimism
    /// @param l1Fees The amount of fees sent to L1 distributor
    /// @param netShare The amount of fees sent to the net fee distributor
    event FeesDistributed(uint256 optimismShare, uint256 l1Fees, uint256 netShare);

    /// @notice Thrown when an address provided in the constructor is zero
    error AmountZero();

    /// @notice Thrown when a transfer fails
    error TransferFailed();

    /// @notice Thrown when an address that is not a vault tries to deposit fees
    error OnlyVaults();

    /// @notice Thrown when a fee vault is configured to withdraw to L2
    error MustWithdrawToL2();

    /// @notice Thrown when a fee vault is not configured to withdraw to the fee splitter
    error MustWithdrawToFeeSplitter();

    /// @notice Distributes the fees collected from the fee vaults to their respective destinations
    /// @return feesDistributed Whether any fees were distributed
    function distributeFees() external returns (bool feesDistributed);
}
