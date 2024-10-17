// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {FeeSplitter} from '../src/FeeSplitter/FeeSplitter.sol';
import {L1Splitter} from '../src/FeeSplitter/L1Splitter.sol';
import {INetFeeSplitter, NetFeeSplitter} from '../src/FeeSplitter/NetFeeSplitter.sol';
import {Script} from 'forge-std/Script.sol';

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();
        address l1Wallet = address(0); // todo
        uint256 feeDisbursementInterval = 1 days;
        uint256 withdrawalMinAmount = 0.1 ether;
        address netFeeRecipient = address(0); // todo
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({admin: netFeeRecipient, allocation: 10_000});
        address[] memory initialRecipients = new address[](1);
        initialRecipients[0] = netFeeRecipient;
        address opWallet = address(0); // todo
        L1Splitter l1Splitter = new L1Splitter(l1Wallet, feeDisbursementInterval, withdrawalMinAmount);
        NetFeeSplitter netFeeSplitter = new NetFeeSplitter(initialRecipients, recipientData);
        new FeeSplitter(opWallet, address(l1Splitter), address(netFeeSplitter));
        vm.stopBroadcast();
    }
}
