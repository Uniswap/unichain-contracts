// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';

import {IL1Splitter} from '../interfaces/FeeSplitter/IL1Splitter.sol';
import {IL2StandardBridge} from '../interfaces/optimism/IL2StandardBridge.sol';

/// @title L1Splitter
/// @notice Withdraws the L1 fees to the L1 wallet via the L2 Standard Bridge.
contract L1Splitter is IL1Splitter {
    /// @dev The minimum gas limit for the FeeSplitter withdrawal transaction to L1.
    uint32 internal constant WITHDRAWAL_MIN_GAS = 35_000;

    address internal immutable L1_WALLET;
    uint256 internal immutable FEE_DISBURSEMENT_INTERVAL;
    /// @dev The minimum amount of ETH that must be sent to L1.
    uint256 internal immutable WITHDRAWAL_MIN_AMOUNT;

    uint256 public lastDisbursementTime;

    constructor(address l1Wallet, uint256 feeDisbursementInterval, uint256 withdrawalMinAmount) {
        L1_WALLET = l1Wallet;
        FEE_DISBURSEMENT_INTERVAL = feeDisbursementInterval;
        WITHDRAWAL_MIN_AMOUNT = withdrawalMinAmount;
    }

    /// @inheritdoc IL1Splitter
    function withdraw() external {
        uint256 balance = address(this).balance;
        if (balance < WITHDRAWAL_MIN_AMOUNT) revert InsufficientWithdrawalAmount();
        if (block.timestamp < lastDisbursementTime + FEE_DISBURSEMENT_INTERVAL) {
            revert DisbursementIntervalNotReached();
        }

        lastDisbursementTime = block.timestamp;

        IL2StandardBridge(Predeploys.L2_STANDARD_BRIDGE).bridgeETHTo{value: balance}(
            L1_WALLET, WITHDRAWAL_MIN_GAS, bytes('')
        );

        emit Withdrawal(balance);
    }

    receive() external payable {
        // receive any ETH sent to this contract
    }
}
