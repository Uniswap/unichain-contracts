// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface INetFeeSplitter {
    /// @notice Recipient data for an individual recipient
    /// @custom:field setter The setter address managing the recipient
    /// @custom:field allocation The allocation of the recipient
    struct Recipient {
        address setter;
        uint256 allocation;
    }

    /// @notice Emitted when a recipient's allocation is transferred
    /// @param setter The setter address managing the recipient
    /// @param from The previous recipient address
    /// @param to The new recipient address
    /// @param allocation The allocation transferred
    event AllocationTransferred(address indexed setter, address indexed from, address indexed to, uint256 allocation);

    /// @notice Emitted when a recipient's setter is transferred
    /// @param recipient The recipient address
    /// @param previousSetter The previous setter address
    /// @param newSetter The new setter address
    event SetterTransferred(address indexed recipient, address indexed previousSetter, address indexed newSetter);

    /// @notice Emitted when fees are withdrawn by recipient
    /// @param recipient The recipient address
    /// @param to The address the fees were withdrawn to
    /// @param amount The amount of fees withdrawn
    event Withdrawn(address indexed recipient, address indexed to, uint256 amount);

    /// @notice Thrown when the recipients array is not the same length as the recipientData array
    error InvalidRecipients();

    /// @notice Thrown when a duplicate recipient is added
    error DuplicateRecipient();

    /// @notice Thrown when an setter address is zero
    error SetterZero();

    /// @notice Thrown when a recipient already has a setter
    error SetterAlreadySet();

    /// @notice Thrown when a recipient address is zero
    error RecipientZero();

    /// @notice Thrown when a recipient allocation is zero or zero allocation is transferred
    error AllocationZero();

    /// @notice Thrown when the total allocation is not the same as the sum of the recipient balances
    error InvalidTotalAllocation();

    /// @notice Thrown when the caller is not the setter
    error Unauthorized();

    /// @notice Thrown when there is insufficient allocation to perform a transfer
    error InsufficientAllocation();

    /// @notice Thrown when a withdrawal fails
    error WithdrawalFailed();

    /// @notice Transfers a allocation from one recipient to another
    /// @param from The recipient address to transfer from
    /// @param recipient The recipient address to transfer to
    /// @param allocation The allocation to transfer
    /// @dev reverts if the recipient doesn't have an admin
    function transferAllocation(address from, address recipient, uint256 allocation) external;

    /// @notice Transfers the allocation of a recipient to another recipient and sets the setter of the recipient
    /// @param from The recipient address to transfer from
    /// @param recipient The recipient address to transfer to
    /// @param newAdmin The new setter address for the recipient
    /// @param allocation The allocation to transfer
    /// @dev reverts if the recipient already has a setter
    function transferAllocationAndSetSetter(address from, address recipient, address newAdmin, uint256 allocation)
        external;

    /// @notice Transfers the setter of a recipient to a new setter
    /// @param recipient The recipient address
    /// @param newSetter The new setter address
    function transferSetter(address recipient, address newSetter) external;

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

    /// @notice Gets the setter of a recipient
    /// @param recipient The recipient address
    /// @return setter The setter of the recipient
    function setterOf(address recipient) external view returns (address);
}
