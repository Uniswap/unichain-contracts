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
    function transfer(address from, address recipient, uint256 allocation) external {
        if (recipient == address(0)) revert RecipientZero();
        if (setterOf(from) != msg.sender) revert Unauthorized();
        if (setterOf(recipient) == address(0)) {
            // recipient does not exist yet, make recipient the setter
            recipients[recipient] = Recipient(recipient, 0);
        }
        _updateFees(from);
        _updateFees(recipient);

        if (balanceOf(from) < allocation) revert InsufficientAllocation();
        recipients[from].allocation -= allocation;
        recipients[recipient].allocation += allocation;
        emit AllocationTransferred(msg.sender, from, recipient, allocation);
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

    function _calculateFees(address account) private view returns (uint256) {
        return (recipients[account].allocation * (_index - _indexOf[account])) / MAGNITUDE;
    }

    function _updateFees(address account) private {
        _earned[account] += _calculateFees(account);
        _indexOf[account] = _index;
    }
}
