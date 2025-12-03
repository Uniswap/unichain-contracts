// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {NetFeeSplitter} from '../../../src/FeeSplitter/NetFeeSplitter.sol';
import {FeeRecipientCoordinator} from '../../../src/FeeSplitter/periphery/FeeRecipientCoordinator.sol';
import {FeeRecipientForwarder} from '../../../src/FeeSplitter/periphery/FeeRecipientForwarder.sol';
import {INetFeeSplitter} from '../../../src/interfaces/FeeSplitter/INetFeeSplitter.sol';
import {IFeeRecipientForwarder} from '../../../src/interfaces/periphery/IFeeRecipientForwarder.sol';

contract FeeRecipientCoordinatorTest is Test {
    NetFeeSplitter splitter;
    address alice;
    address bob;
    address setter;

    FeeRecipientCoordinator coordinator;
    IFeeRecipientForwarder[] feeRecipientForwarders = new IFeeRecipientForwarder[](2);

    function setUp() public {
        alice = makeAddr('alice');
        bob = makeAddr('bob');

        setter = makeAddr('setter');

        address[] memory recipients = new address[](1);
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);

        // First deploy splitter with setter as initial recipient
        recipients[0] = setter;
        recipientData[0] = INetFeeSplitter.Recipient({setter: setter, allocation: 10_000});
        splitter = new NetFeeSplitter(recipients, recipientData);

        // Deploy FeeRecipientForwarder
        FeeRecipientForwarder forwarder1 = new FeeRecipientForwarder(address(splitter), alice);
        FeeRecipientForwarder forwarder2 = new FeeRecipientForwarder(address(splitter), bob);

        feeRecipientForwarders[0] = forwarder1;
        feeRecipientForwarders[1] = forwarder2;

        // Transfer allocation from setter to feeRecipientForwarder
        vm.startPrank(setter);
        splitter.transferAllocationAndSetSetter(setter, address(forwarder1), setter, 5000);
        splitter.transferAllocationAndSetSetter(setter, address(forwarder2), setter, 5000);
        vm.stopPrank();

        coordinator = new FeeRecipientCoordinator(feeRecipientForwarders);
    }

    function test_Withdraw_SendsFeesToRecipient(uint256 amount) public {
        amount = bound(amount, 0.001 ether, 1000 ether);

        vm.deal(address(this), amount);

        // Send fees to the netFeeSplitter
        (bool success,) = address(splitter).call{value: amount}('');
        assertTrue(success);

        // Withdraw via FeeRecipientCoordinator
        uint256 totalAmount = coordinator.withdraw();

        // Verify the correct amount was returned
        assertApproxEqAbs(totalAmount, amount, 1, 'total amount should be within 1 wei of the amount');

        // Verify the recipients received the funds
        assertEq(alice.balance, amount / 2);
        assertEq(bob.balance, amount / 2);
    }

    function test_AnyoneCanWithdraw(uint256 amount) public {
        amount = bound(amount, 0.001 ether, 1000 ether);

        vm.deal(address(this), amount);

        // Send fees to the netFeeSplitter
        (bool success,) = address(splitter).call{value: amount}('');
        assertTrue(success);

        // Anyone can call withdraw
        address randomCaller = makeAddr('randomCaller');
        vm.prank(randomCaller);
        uint256 totalAmount = coordinator.withdraw();

        assertApproxEqAbs(totalAmount, amount, 1, 'total amount should be within 1 wei of the amount');
        assertEq(alice.balance, amount / 2);
        assertEq(bob.balance, amount / 2);
    }
}
