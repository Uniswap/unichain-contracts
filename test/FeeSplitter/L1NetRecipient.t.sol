// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {L1NetRecipient} from '../../src/FeeSplitter/L1NetRecipient.sol';

import {INetFeeSplitter, NetFeeSplitter} from '../../src/FeeSplitter/NetFeeSplitter.sol';
import {IL1Splitter} from '../../src/interfaces/FeeSplitter/IL1Splitter.sol';
import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';

contract L1NetRecipientTest is Test {
    L1NetRecipient internal recipient;

    function test_ShouldWithdrawFromNetFeeSplitterAndWithdraw() public {
        address[] memory recipients = new address[](1);
        recipients[0] = makeAddr('recipient');
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);
        recipientData[0] = INetFeeSplitter.Recipient({setter: makeAddr('setter'), allocation: 10_000});
        NetFeeSplitter splitter = new NetFeeSplitter(recipients, recipientData);
        recipient = new L1NetRecipient(address(splitter), makeAddr('owner'), makeAddr('l1Wallet'), 0, 0.1 ether);
        vm.prank(makeAddr('setter'));
        splitter.transfer(makeAddr('recipient'), address(recipient), 10_000);
        vm.etch(Predeploys.L2_STANDARD_BRIDGE, address(new MockL2StandardBridge()).code);
        (bool success,) = address(splitter).call{value: 10 ether}('');
        assertTrue(success);
        assertEq(address(Predeploys.L2_STANDARD_BRIDGE).balance, 0);
        assertEq(splitter.earnedFees(address(recipient)), 10 ether);
        vm.expectEmit(true, true, true, true);
        emit IL1Splitter.Withdrawal(makeAddr('l1Wallet'), 10 ether);
        recipient.withdraw();
        assertEq(address(Predeploys.L2_STANDARD_BRIDGE).balance, 10 ether);
        assertEq(splitter.earnedFees(address(recipient)), 0);
    }
}

contract MockL2StandardBridge {
    function bridgeETHTo(address, uint32, bytes calldata) external payable {}
}
