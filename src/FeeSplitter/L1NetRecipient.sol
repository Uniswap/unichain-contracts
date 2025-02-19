// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {INetFeeSplitter} from '../interfaces/FeeSplitter/INetFeeSplitter.sol';
import {L1Splitter} from './L1Splitter.sol';

/// @title L1 Net Recipient
/// @notice Pulls fees from the `NetFeeSplitter` and withdraws them to L1
contract L1NetRecipient is L1Splitter {
    INetFeeSplitter private immutable NET_FEE_SPLITTER;

    constructor(
        address netFeeSplitter,
        address initialOwner,
        address l1Wallet,
        uint48 feeDisbursementInterval_,
        uint256 minWithdrawalAmount_
    ) L1Splitter(initialOwner, l1Wallet, feeDisbursementInterval_, minWithdrawalAmount_) {
        NET_FEE_SPLITTER = INetFeeSplitter(netFeeSplitter);
    }

    function withdraw() public override returns (uint256 balance) {
        NET_FEE_SPLITTER.withdrawFees(address(this));
        return super.withdraw();
    }
}
