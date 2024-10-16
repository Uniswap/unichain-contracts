// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface INetFeeSplitter {
    /// @notice Recipient data for an individual recipient
    /// @custom:field admin The admin address managing the recipient
    /// @custom:field allocation The allocation of the recipient
    struct Recipient {
        address admin;
        uint256 allocation;
    }

    /// @notice Emitted when a recipient's allocation is transferred
    /// @param admin The admin address managing the recipient
    /// @param from The previous recipient address
    /// @param to The new recipient address
    /// @param allocation The allocation transferred
    event TransferAllocation(address indexed admin, address indexed from, address indexed to, uint256 allocation);

    /// @notice Emitted when a recipient's admin is transferred
    /// @param recipient The recipient address
    /// @param previousAdmin The previous admin address
    /// @param newAdmin The new admin address
    event TransferAdmin(address indexed recipient, address indexed previousAdmin, address indexed newAdmin);

    /// @notice Emitted when fees are withdrawn by recipient
    /// @param recipient The recipient address
    /// @param to The address the fees were withdrawn to
    /// @param amount The amount of fees withdrawn
    event Withdrawn(address indexed recipient, address indexed to, uint256 amount);

    /// @notice Thrown when the recipients array is not the same length as the recipientData array
    error InvalidRecipients();

    /// @notice Thrown when a duplicate recipient is added
    error DuplicateRecipient();

    /// @notice Thrown when an admin address is zero
    error AdminZero();

    /// @notice Thrown when a recipient address is zero
    error RecipientZero();

    /// @notice Thrown when a recipient allocation is zero
    error AllocationZero();

    /// @notice Thrown when the total allocation is not the same as the sum of the recipient balances
    error InvalidTotalAllocation();

    /// @notice Thrown when the caller is not the admin
    error Unauthorized();

    /// @notice Thrown when there is insufficient allocation to perform a transfer
    error InsufficientAllocation();

    /// @notice Thrown when a withdrawal fails
    error WithdrawalFailed();

    /// @notice Transfers a allocation from one recipient to another
    /// @param from The recipient address to transfer from
    /// @param recipient The recipient address to transfer to
    /// @param allocation The allocation to transfer
    function transfer(address from, address recipient, uint256 allocation) external;

    /// @notice Transfers the admin of a recipient to a new admin
    /// @param recipient The recipient address
    /// @param newAdmin The new admin address
    function transferAdmin(address recipient, address newAdmin) external;

    /// @notice Withdraws the fees earned by a recipient
    /// @param to The address to withdraw the fees to
    /// @return amount The amount of fees withdrawn
    function withdrawFees(address to) external returns (uint256 amount);

    /// @notice Calculates the fees earned by a recipient
    /// @param account The recipient address
    /// @return amount The amount of fees earned
    function earnedFees(address account) external view returns (uint256);

    /// @notice Gets the allocation of a recipient
    /// @param recipient The recipient address
    /// @return allocation The allocation of the recipient
    function balanceOf(address recipient) external view returns (uint256);

    /// @notice Gets the admin of a recipient
    /// @param recipient The recipient address
    /// @return admin The admin of the recipient
    function adminOf(address recipient) external view returns (address);
}
