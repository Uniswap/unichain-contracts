// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {INetFeeSplitter, NetFeeSplitter} from '../../src/FeeSplitter/NetFeeSplitter.sol';
import {TokenJarRecipient} from '../../src/FeeSplitter/TokenJarRecipient.sol';

contract TokenJarRecipientTest is Test {
    NetFeeSplitter splitter;
    TokenJarRecipient tokenJarRecipient;
    address tokenJar;
    address setter;

    function setUp() public {
        tokenJar = makeAddr('tokenJar');
        setter = makeAddr('setter');

        address[] memory recipients = new address[](1);
        INetFeeSplitter.Recipient[] memory recipientData = new INetFeeSplitter.Recipient[](1);

        // We'll deploy the TokenJarRecipient first to get its address, then set it as a recipient
        // But we need the splitter address first. Use create2 or just deploy in order.

        // Deploy splitter with a placeholder, then redeploy with correct address
        // Actually, let's deploy TokenJarRecipient after splitter, then transfer allocation to it

        // First deploy splitter with setter as initial recipient
        recipients[0] = setter;
        recipientData[0] = INetFeeSplitter.Recipient({setter: setter, allocation: 10_000});
        splitter = new NetFeeSplitter(recipients, recipientData);

        // Deploy TokenJarRecipient
        tokenJarRecipient = new TokenJarRecipient(address(splitter), tokenJar);

        // Transfer allocation from setter to tokenJarRecipient
        vm.prank(setter);
        splitter.transferAllocationAndSetSetter(setter, address(tokenJarRecipient), setter, 10_000);
    }

    function test_Withdraw_SendsFeesToTokenJar() public {
        // Send fees to the splitter
        (bool success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);

        // Verify tokenJarRecipient has earned fees
        assertEq(splitter.earnedFees(address(tokenJarRecipient)), 1 ether);

        // Withdraw via TokenJarRecipient
        uint256 amount = tokenJarRecipient.withdraw();

        // Verify the correct amount was returned
        assertEq(amount, 1 ether);

        // Verify tokenJar received the funds
        assertEq(tokenJar.balance, 1 ether);

        // Verify no more earned fees
        assertEq(splitter.earnedFees(address(tokenJarRecipient)), 0);
    }

    function test_Withdraw_CallableByAnyone() public {
        // Send fees to the splitter
        (bool success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);

        // Anyone can call withdraw
        address randomCaller = makeAddr('randomCaller');
        vm.prank(randomCaller);
        uint256 amount = tokenJarRecipient.withdraw();

        assertEq(amount, 1 ether);
        assertEq(tokenJar.balance, 1 ether);
    }

    function test_Withdraw_ReturnsZeroWhenNoFees() public {
        uint256 amount = tokenJarRecipient.withdraw();
        assertEq(amount, 0);
        assertEq(tokenJar.balance, 0);
    }

    function test_Withdraw_MultipleTimes() public {
        // First batch of fees
        (bool success,) = address(splitter).call{value: 1 ether}('');
        assertTrue(success);

        tokenJarRecipient.withdraw();
        assertEq(tokenJar.balance, 1 ether);

        // Second batch of fees
        (success,) = address(splitter).call{value: 2 ether}('');
        assertTrue(success);

        tokenJarRecipient.withdraw();
        assertEq(tokenJar.balance, 3 ether);
    }

    function test_Withdraw_Fuzz(uint256 feeAmount) public {
        feeAmount = bound(feeAmount, 0.001 ether, 1000 ether);

        (bool success,) = address(splitter).call{value: feeAmount}('');
        assertTrue(success);

        uint256 amount = tokenJarRecipient.withdraw();
        assertEq(amount, feeAmount);
        assertEq(tokenJar.balance, feeAmount);
    }
}
