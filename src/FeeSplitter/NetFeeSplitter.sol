// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {INetFeeSplitter} from '../interfaces/FeeSplitter/INetFeeSplitter.sol';

/// @title NetFeeSplitter
/// @notice Splits net fees between multiple recipients. Recipients are managed by setters. Setters can transfer the entire allocation or a portion of it to other recipients.
contract NetFeeSplitter is INetFeeSplitter {
    uint256 internal constant TOTAL_ALLOCATION = 10_000;
    uint256 private constant MAGNITUDE = 1e30;

    uint256 private _index;
    mapping(address recipient => uint256 index) private _indexOf;
    mapping(address recipient => uint256 _earned) private _earned;

    mapping(address recipient => Recipient) public recipients;

    constructor(address[] memory initialRecipients, Recipient[] memory recipientData) {
        uint256 totalAllocation;
        uint256 length = initialRecipients.length;
        if (initialRecipients.length != recipientData.length) revert InvalidRecipients();
        for (uint256 i = 0; i < length; i++) {
            address recipient = initialRecipients[i];
            bool duplicateRecipient = false;
            assembly {
                duplicateRecipient := tload(recipient)
                tstore(recipient, 1)
            }
            if (duplicateRecipient) revert DuplicateRecipient();
            if (recipientData[i].setter == address(0)) revert SetterZero();
            if (recipient == address(0)) revert RecipientZero();
            if (recipientData[i].allocation == 0) revert AllocationZero();
            recipients[recipient] = recipientData[i];
            totalAllocation += recipientData[i].allocation;
        }
        if (totalAllocation != TOTAL_ALLOCATION) revert InvalidTotalAllocation();
    }

    /// @dev Keep track of incoming fees
    receive() external payable {
        _index += (msg.value * MAGNITUDE) / TOTAL_ALLOCATION;
    }

    /// @inheritdoc INetFeeSplitter
    function transferAllocation(address oldRecipient, address newRecipient, uint256 allocation) external {
        if (setterOf(newRecipient) == address(0)) revert SetterZero();
        _transfer(oldRecipient, newRecipient, allocation);
    }

    /// @inheritdoc INetFeeSplitter
    function transferAllocationAndSetSetter(
        address oldRecipient,
        address newRecipient,
        address newAdmin,
        uint256 allocation
    ) external {
        if (setterOf(newRecipient) != address(0)) revert SetterAlreadySet();
        if (newAdmin == address(0)) revert SetterZero();
        recipients[newRecipient] = Recipient(newAdmin, 0);
        emit SetterTransferred(newRecipient, address(0), newAdmin);
        _transfer(oldRecipient, newRecipient, allocation);
    }

    /// @inheritdoc INetFeeSplitter
    function transferSetter(address recipient, address newSetter) external {
        if (newSetter == address(0)) revert SetterZero();
        address currentSetter = setterOf(recipient);
        if (currentSetter != msg.sender) revert Unauthorized();
        recipients[recipient].setter = newSetter;
        emit SetterTransferred(recipient, currentSetter, newSetter);
    }

    /// @inheritdoc INetFeeSplitter
    function withdrawFees(address to) external returns (uint256 amount) {
        _updateFees(msg.sender);
        amount = _earned[msg.sender];
        if (amount != 0) {
            _earned[msg.sender] = 0;
            (bool success,) = to.call{value: amount}('');
            if (!success) revert WithdrawalFailed();
        }
        emit Withdrawn(msg.sender, to, amount);
    }

    /// @inheritdoc INetFeeSplitter
    function earnedFees(address account) external view returns (uint256) {
        return _earned[account] + _calculateFees(account);
    }

    /// @inheritdoc INetFeeSplitter
    function balanceOf(address recipient) public view returns (uint256) {
        return recipients[recipient].allocation;
    }

    /// @inheritdoc INetFeeSplitter
    function setterOf(address recipient) public view returns (address) {
        return recipients[recipient].setter;
    }

    function _transfer(address oldRecipient, address newRecipient, uint256 allocation) private {
        if (setterOf(oldRecipient) != msg.sender) revert Unauthorized();
        if (newRecipient == address(0)) revert RecipientZero();
        if (allocation == 0) revert AllocationZero();
        _updateFees(oldRecipient);
        _updateFees(newRecipient);

        if (balanceOf(oldRecipient) < allocation) revert InsufficientAllocation();
        recipients[oldRecipient].allocation -= allocation;
        recipients[newRecipient].allocation += allocation;
        emit AllocationTransferred(msg.sender, oldRecipient, newRecipient, allocation);
    }

    function _updateFees(address account) private {
        _earned[account] += _calculateFees(account);
        _indexOf[account] = _index;
    }

    function _calculateFees(address account) private view returns (uint256) {
        return (recipients[account].allocation * (_index - _indexOf[account])) / MAGNITUDE;
    }
}
