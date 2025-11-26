// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {INetFeeSplitter} from '../interfaces/FeeSplitter/INetFeeSplitter.sol';

/// @title Token Jar Recipient
/// @notice A recipient contract for the NetFeeSplitter that forwards fees to a token jar
contract TokenJarRecipient {
    INetFeeSplitter private immutable NET_FEE_SPLITTER;
    address private immutable TOKEN_JAR;

    constructor(address netFeeSplitter, address tokenJar) {
        NET_FEE_SPLITTER = INetFeeSplitter(netFeeSplitter);
        TOKEN_JAR = tokenJar;
    }

    /// @notice Withdraws fees from the NetFeeSplitter and sends them to the token jar
    /// @return amount The amount of fees withdrawn
    function withdraw() external returns (uint256 amount) {
        return NET_FEE_SPLITTER.withdrawFees(TOKEN_JAR);
    }
}
