// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {FeeRecipientForwarder} from '../../src/FeeSplitter/periphery/FeeRecipientForwarder.sol';
import {INetFeeSplitter} from '../../src/interfaces/FeeSplitter/INetFeeSplitter.sol';
import {IFeeRecipientForwarder} from '../../src/interfaces/periphery/IFeeRecipientForwarder.sol';
import {Script, stdJson} from 'forge-std/Script.sol';
import {console2} from 'forge-std/console2.sol';

contract DeployAll is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();

        string memory input = vm.readFile('script/periphery/input.json');
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address netFeeSplitter = input.readAddress(string.concat(chainIdSlug, '.netFeeSplitter'));
        address tokenJar = input.readAddress(string.concat(chainIdSlug, '.tokenJar'));

        // Create two forwarders with TokenJar as the recipient
        FeeRecipientForwarder forwarder = new FeeRecipientForwarder(netFeeSplitter, tokenJar);
        console2.log('forwarder deployed to', address(forwarder));

        vm.stopBroadcast();
    }
}
