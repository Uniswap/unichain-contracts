// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IL1Splitter {
    /// @notice Emitted when the contract is withdrawn
    /// @param recipient The recipient of the withdrawal
    /// @param amount The amount of ETH withdrawn
    event Withdrawal(address indexed recipient, uint256 amount);

    /// @notice Emitted when the L1 recipient is updated
    /// @param oldRecipient The old L1 recipient
    /// @param newRecipient The new L1 recipient
    event L1RecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    /// @notice Emitted when the fee disbursement interval is updated
    /// @param oldInterval The old fee disbursement interval in seconds
    /// @param newInterval The new fee disbursement interval in seconds
    event FeeDisbursementIntervalUpdated(uint48 oldInterval, uint48 newInterval);

    /// @notice Emitted when the minimum withdrawal amount is updated
    /// @param oldAmount The old minimum withdrawal amount
    /// @param newAmount The new minimum withdrawal amount
    event MinWithdrawalAmountUpdated(uint256 oldAmount, uint256 newAmount);

    /// @notice Thrown when the contract is withdrawn with an insufficient amount
    error InsufficientWithdrawalAmount();
    /// @notice Thrown when the contract is withdrawn before the disbursement interval is reached
    error DisbursementIntervalNotReached();

    /// @notice Thrown when the address is zero
    error AddressZero();

    /// @notice Thrown when the disbursement interval is less than the minimum disbursement interval
    error MinDisbursementInterval();

    /// @notice Thrown when the minimum withdrawal amount is less than the minimum withdrawal amount
    error MinWithdrawalAmount();

    /// @notice Withdraws the balance of the contract to L1
    /// @return The amount of ETH withdrawn
    function withdraw() external returns (uint256);

    /// @notice Updates the L1 recipient
    /// @param newRecipient The new L1 recipient
    function updateL1Recipient(address newRecipient) external;

    /// @notice Updates the fee disbursement interval
    /// @param newInterval The new fee disbursement interval in seconds
    function updateFeeDisbursementInterval(uint48 newInterval) external;

    /// @notice Updates the minimum withdrawal amount
    /// @param newAmount The new minimum withdrawal amount
    function updateMinWithdrawalAmount(uint256 newAmount) external;

    /// @return The L1 recipient.
    function l1Recipient() external view returns (address);

    /// @return The fee disbursement interval in seconds.
    function feeDisbursementInterval() external view returns (uint48);

    /// @return The minimum amount of ETH that must be sent to L1.
    function minWithdrawalAmount() external view returns (uint256);

    /// @return The last disbursement time
    function lastDisbursementTime() external view returns (uint48);
}
