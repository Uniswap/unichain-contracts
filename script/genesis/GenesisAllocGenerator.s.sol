// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {FeeSplitter} from '../../src/FeeSplitter/FeeSplitter.sol';

import {L1NetRecipient} from '../../src/FeeSplitter/L1NetRecipient.sol';
import {L1Splitter} from '../../src/FeeSplitter/L1Splitter.sol';
import {INetFeeSplitter, NetFeeSplitter} from '../../src/FeeSplitter/NetFeeSplitter.sol';

import {Process} from '@eth-optimism-bedrock/scripts/libraries/Process.sol';
import {Script, console} from 'forge-std/Script.sol';

contract GenesisAllocGenerator is Script {
    function run() public {
        address feeSplitterAddress = 0x4300c0D3c0d3c0d3c0d3c0d3C0D3c0d3c0d30001;
        address opForwarderAddress = 0x4300C0D3C0D3C0D3C0d3C0d3c0d3C0d3C0d30002;
        address l1ForwarderAddress = 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003;
        address netFeeSplitterAddress = 0x4300c0D3c0D3c0D3c0D3c0D3C0D3c0d3c0D30004;

        address feeSplitter = address(new FeeSplitter(opForwarderAddress, l1ForwarderAddress, netFeeSplitterAddress));
        vm.etch(feeSplitterAddress, feeSplitter.code);
        reset(feeSplitter);

        {
            // deploy optimsism fee forwarder contract and copy code and storage to address
            address opRecipient = address(0xa3d596EAfaB6B13Ab18D40FaE1A962700C84ADEa); // Op fee recipient on L1
            address opAdmin = address(0xb4E696eAFAB6B13AB18D40fAE1a962700C84BefB); // Admin of fee forwarder on L1
            uint48 opFeeDisbursementInterval = 1 days;
            uint256 opMinWithdrawalAmount = 10 ether;
            address opForwarder =
                address(new L1Splitter(opAdmin, opRecipient, opFeeDisbursementInterval, opMinWithdrawalAmount));
            vm.etch(opForwarderAddress, opForwarder.code);
            vm.copyStorage(opForwarder, opForwarderAddress);
            reset(opForwarder);
        }

        {
            // deploy l1 fee forwarder contract and copy code and storage to address
            address l1Wallet = address(0x2F60A5184c63ca94f82a27100643DbAbe4F3f7Fd); // L1 fee recipient on L1
            address l1Admin = address(0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2); // Admin of fee forwarder on L1
            uint48 l1FeeDisbursementInterval = 1 days;
            uint256 l1MinWithdrawalAmount = 10 ether;
            address l1Forwarder =
                address(new L1Splitter(l1Admin, l1Wallet, l1FeeDisbursementInterval, l1MinWithdrawalAmount));
            vm.etch(l1ForwarderAddress, l1Forwarder.code);
            vm.copyStorage(l1Forwarder, l1ForwarderAddress);
            reset(l1Forwarder);
        }

        {
            // deploy net fee splitter contract and copy code and storage to address
            address labsRecipient = address(0xaE85BbB6c1c1807a64A88F1a1f978740c8a0Dba0); // temporary EOA admin + recipient for labs
            uint256 labsAllocation = 2400;
            address foundationRecipient = address(0x3fCbACd76037534D2AAeB9a17f4e631dd64fbe31); // temporary EOA admin + recipient for foundation
            uint256 foundationAllocation = 7600;

            INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](2);
            recipientData[0] = INetFeeSplitter.Recipient({setter: labsRecipient, allocation: labsAllocation});
            recipientData[1] =
                INetFeeSplitter.Recipient({setter: foundationRecipient, allocation: foundationAllocation});
            address[] memory initialRecipients = new address[](2);
            initialRecipients[0] = labsRecipient;
            initialRecipients[1] = foundationRecipient;
            address netFeeSplitter = address(new NetFeeSplitter(initialRecipients, recipientData));
            vm.etch(netFeeSplitterAddress, netFeeSplitter.code);
            vm.copyStorage(netFeeSplitter, netFeeSplitterAddress);
            reset(netFeeSplitter);
        }
        writeGenesisAllocs('script/genesis/allocs.json');
    }

    /// @notice Writes the genesis allocs, i.e. the state dump, to disk
    function writeGenesisAllocs(string memory _path) internal {
        console.log('Writing state dump to: %s', _path);
        vm.dumpState(_path);
        sortJsonByKeys(_path);
    }

    /// @notice Sorts the allocs by address
    function sortJsonByKeys(string memory _path) internal {
        string[] memory commands = new string[](3);
        commands[0] = 'bash';
        commands[1] = '-c';
        commands[2] = string.concat("cat <<< $(jq -S '.' ", _path, ') > ', _path);
        Process.run(commands);
    }

    function reset(address target) internal {
        vm.etch(target, '');
        vm.copyStorage(address(0), target);
        vm.resetNonce(target);
    }
}
