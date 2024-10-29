// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';

import {IL1Splitter} from '../interfaces/FeeSplitter/IL1Splitter.sol';
import {IL2StandardBridge} from '../interfaces/optimism/IL2StandardBridge.sol';
import {Ownable, Ownable2Step} from '@openzeppelin/contracts/access/Ownable2Step.sol';

/// @title L1Splitter
/// @notice Withdraws the L1 fees to the L1 wallet via the L2 Standard Bridge.
contract L1Splitter is IL1Splitter, Ownable2Step {
    /// @dev The minimum gas limit for the FeeSplitter withdrawal transaction to L1.
    uint32 internal constant WITHDRAWAL_MIN_GAS = 35_000;

    /// @inheritdoc IL1Splitter
    address public l1Recipient;
    /// @inheritdoc IL1Splitter
    uint48 public feeDisbursementInterval;
    /// @inheritdoc IL1Splitter
    uint48 public lastDisbursementTime;
    /// @inheritdoc IL1Splitter
    uint256 public minWithdrawalAmount;

    constructor(address initialOwner, address l1Wallet, uint48 feeDisbursementInterval_, uint256 minWithdrawalAmount_)
        Ownable(initialOwner)
    {
        _updateL1Recipient(l1Wallet);
        _updateFeeDisbursementInterval(feeDisbursementInterval_);
        _updateMinWithdrawalAmount(minWithdrawalAmount_);
    }

    /// @inheritdoc IL1Splitter
    function withdraw() public virtual returns (uint256 balance) {
        balance = address(this).balance;
        if (balance < minWithdrawalAmount) revert InsufficientWithdrawalAmount();
        if (block.timestamp < lastDisbursementTime + feeDisbursementInterval) {
            revert DisbursementIntervalNotReached();
        }

        lastDisbursementTime = uint48(block.timestamp);

        address recipient = l1Recipient;
        IL2StandardBridge(Predeploys.L2_STANDARD_BRIDGE).bridgeETHTo{value: balance}(
            recipient, WITHDRAWAL_MIN_GAS, bytes('')
        );

        emit Withdrawal(recipient, balance);
    }

    /// @inheritdoc IL1Splitter
    function updateL1Recipient(address newRecipient) public onlyOwner {
        _updateL1Recipient(newRecipient);
    }

    /// @inheritdoc IL1Splitter
    function updateFeeDisbursementInterval(uint48 newInterval) public onlyOwner {
        _updateFeeDisbursementInterval(newInterval);
    }

    /// @inheritdoc IL1Splitter
    function updateMinWithdrawalAmount(uint256 newAmount) public onlyOwner {
        _updateMinWithdrawalAmount(newAmount);
    }

    function _updateL1Recipient(address newRecipient) internal {
        emit L1RecipientUpdated(l1Recipient, newRecipient);
        l1Recipient = newRecipient;
    }

    function _updateFeeDisbursementInterval(uint48 newInterval) internal {
        emit FeeDisbursementIntervalUpdated(feeDisbursementInterval, newInterval);
        feeDisbursementInterval = newInterval;
    }

    function _updateMinWithdrawalAmount(uint256 newAmount) internal {
        emit MinWithdrawalAmountUpdated(minWithdrawalAmount, newAmount);
        minWithdrawalAmount = newAmount;
    }

    receive() external payable {
        // receive any ETH sent to this contract
    }
}
