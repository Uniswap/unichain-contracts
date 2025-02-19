// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {BaseFeeVault, Types} from '@eth-optimism-bedrock/src/L2/BaseFeeVault.sol';
import {L1FeeVault} from '@eth-optimism-bedrock/src/L2/L1FeeVault.sol';
import {SequencerFeeVault} from '@eth-optimism-bedrock/src/L2/SequencerFeeVault.sol';
import {Script, stdJson} from 'forge-std/Script.sol';

contract DeployFeeVaults is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();
        string memory input = vm.readFile('script/FeeVaults/input.json');
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address feeSplitter = input.readAddress(string.concat(chainIdSlug, '.feeSplitter'));
        new BaseFeeVault(feeSplitter, 1, Types.WithdrawalNetwork.L2);
        new L1FeeVault(feeSplitter, 1, Types.WithdrawalNetwork.L2);
        new SequencerFeeVault(feeSplitter, 1, Types.WithdrawalNetwork.L2);
        vm.stopBroadcast();
    }
}
