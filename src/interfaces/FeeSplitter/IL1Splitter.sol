// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IL1Splitter {
    /// @notice Emitted when the contract is withdrawn
    /// @param amount The amount of ETH withdrawn
    event Withdrawal(uint256 amount);

    /// @notice Thrown when the contract is withdrawn with an insufficient amount
    error InsufficientWithdrawalAmount();
    /// @notice Thrown when the contract is withdrawn before the disbursement interval is reached
    error DisbursementIntervalNotReached();

    /// @notice Withdraws the balance of the contract to L1
    function withdraw() external;
}
