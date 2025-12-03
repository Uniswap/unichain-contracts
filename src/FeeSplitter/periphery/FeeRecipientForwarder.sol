// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {INetFeeSplitter} from '../../interfaces/FeeSplitter/INetFeeSplitter.sol';
import {IFeeRecipientForwarder} from '../../interfaces/periphery/IFeeRecipientForwarder.sol';

/// @title Fee Recipient Forwarder
/// @notice A recipient contract for the NetFeeSplitter that forwards fees to another recipient
contract FeeRecipientForwarder is IFeeRecipientForwarder {
    INetFeeSplitter private immutable NET_FEE_SPLITTER;
    address private immutable RECIPIENT;

    constructor(address netFeeSplitter, address recipient) {
        NET_FEE_SPLITTER = INetFeeSplitter(netFeeSplitter);
        RECIPIENT = recipient;
    }

    /// @inheritdoc IFeeRecipientForwarder
    function withdraw() external returns (uint256 amount) {
        return NET_FEE_SPLITTER.withdrawFees(RECIPIENT);
    }
}
