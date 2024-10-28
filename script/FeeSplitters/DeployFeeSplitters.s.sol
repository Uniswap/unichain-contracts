// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {FeeSplitter} from '../../src/FeeSplitter/FeeSplitter.sol';
import {L1Splitter} from '../../src/FeeSplitter/L1Splitter.sol';
import {INetFeeSplitter, NetFeeSplitter} from '../../src/FeeSplitter/NetFeeSplitter.sol';
import {Script, stdJson} from 'forge-std/Script.sol';

contract DeployFeeSplitters is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();
        string memory input = vm.readFile('script/FeeSplitters/input.json');
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address l1Wallet = input.readAddress(string.concat(chainIdSlug, '.l1Wallet'));
        address netFeeRecipient = input.readAddress(string.concat(chainIdSlug, '.netFeeRecipient'));
        address opWallet = input.readAddress(string.concat(chainIdSlug, '.opWallet'));
        address l1SplitterOwner = input.readAddress(string.concat(chainIdSlug, '.l1SplitterOwner'));
        uint48 feeDisbursementInterval = 1 hours;
        uint256 withdrawalMinAmount = 0.01 ether;
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: netFeeRecipient, allocation: 10_000});
        address[] memory initialRecipients = new address[](1);
        initialRecipients[0] = netFeeRecipient;
        L1Splitter l1Splitter = new L1Splitter(l1SplitterOwner, l1Wallet, feeDisbursementInterval, withdrawalMinAmount);
        NetFeeSplitter netFeeSplitter = new NetFeeSplitter(initialRecipients, recipientData);
        new FeeSplitter(opWallet, address(l1Splitter), address(netFeeSplitter));
        vm.stopBroadcast();
    }
}
