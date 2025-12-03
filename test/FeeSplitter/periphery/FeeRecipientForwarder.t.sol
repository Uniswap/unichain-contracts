// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {INetFeeSplitter, NetFeeSplitter} from '../../../src/FeeSplitter/NetFeeSplitter.sol';
import {FeeRecipientForwarder} from '../../../src/FeeSplitter/periphery/FeeRecipientForwarder.sol';

contract FeeRecipientForwarderTest is Test {
    NetFeeSplitter splitter;
    FeeRecipientForwarder feeRecipientForwarder;
    address recipient;
    address setter;

    function setUp() public {
        recipient = makeAddr('recipient');
        setter = makeAddr('setter');

        address[] memory recipients = new address[](1);
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);

        // First deploy splitter with setter as initial recipient
        recipients[0] = setter;
        recipientData[0] = INetFeeSplitter.Recipient({setter: setter, allocation: 10_000});
        splitter = new NetFeeSplitter(recipients, recipientData);

        // Deploy FeeRecipientForwarder
        feeRecipientForwarder = new FeeRecipientForwarder(address(splitter), recipient);

        // Transfer allocation from setter to feeRecipientForwarder
        vm.prank(setter);
        splitter.transferAllocationAndSetSetter(setter, address(feeRecipientForwarder), setter, 10_000);
    }

    function test_Withdraw_SendsFeesToRecipient() public {
        // Send fees to the splitter
        (bool success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);

        // Verify feeRecipientForwarder has earned fees
        assertEq(splitter.earnedFees(address(feeRecipientForwarder)), 1 ether);

        // Withdraw via FeeRecipientForwarder
        uint256 amount = feeRecipientForwarder.withdraw();

        // Verify the correct amount was returned
        assertEq(amount, 1 ether);

        // Verify recipient received the funds
        assertEq(recipient.balance, 1 ether);

        // Verify no more earned fees
        assertEq(splitter.earnedFees(address(feeRecipientForwarder)), 0);
    }

    function test_Withdraw_CallableByAnyone() public {
        // Send fees to the splitter
        (bool success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);

        // Anyone can call withdraw
        address randomCaller = makeAddr('randomCaller');
        vm.prank(randomCaller);
        uint256 amount = feeRecipientForwarder.withdraw();

        assertEq(amount, 1 ether);
        assertEq(recipient.balance, 1 ether);
    }

    function test_Withdraw_ReturnsZeroWhenNoFees() public {
        uint256 amount = feeRecipientForwarder.withdraw();
        assertEq(amount, 0);
        assertEq(recipient.balance, 0);
    }

    function test_Withdraw_MultipleTimes() public {
        // First batch of fees
        (bool success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);

        feeRecipientForwarder.withdraw();
        assertEq(recipient.balance, 1 ether);

        // Second batch of fees
        (success,) = address(splitter).call{value: 2 ether}('');
        assertTrue(success);

        feeRecipientForwarder.withdraw();
        assertEq(recipient.balance, 3 ether);
    }

    function test_Withdraw_Fuzz(uint256 feeAmount) public {
        feeAmount = bound(feeAmount, 0.001 ether, 1000 ether);

        (bool success,) = address(splitter).call{value: feeAmount}('');
        assertTrue(success);

        uint256 amount = feeRecipientForwarder.withdraw();
        assertEq(amount, feeAmount);
        assertEq(recipient.balance, feeAmount);
    }
}
