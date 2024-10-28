// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {IL1Splitter, L1Splitter, Ownable} from '../../src/FeeSplitter/L1Splitter.sol';
import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';

contract L1SplitterTest is Test {
    L1Splitter internal splitter;
    address internal owner = makeAddr('owner');

    function setUp() public {
        splitter = new L1Splitter(owner, makeAddr('l1Wallet'), 1 days, 0.1 ether);
        vm.etch(Predeploys.L2_STANDARD_BRIDGE, address(new MockL2StandardBridge()).code);
    }

    function test_RevertIf_InsufficientWithdrawalAmount() public {
        vm.expectRevert(IL1Splitter.InsufficientWithdrawalAmount.selector);
        splitter.withdraw();
    }

    function test_RevertIf_DisbursementIntervalNotReached() public {
        vm.deal(address(splitter), 0.1 ether);
        vm.expectRevert(IL1Splitter.DisbursementIntervalNotReached.selector);
        splitter.withdraw();
    }

    function test_RevertIf_NotOwner(address notOwner) public {
        vm.assume(notOwner != owner);
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        splitter.updateL1Recipient(makeAddr('l1Wallet'));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        splitter.updateFeeDisbursementInterval(1 days);
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        splitter.updateMinWithdrawalAmount(0.1 ether);
    }

    function test_ShouldUpdateL1Recipient(address newRecipient) public {
        assertEq(splitter.l1Recipient(), makeAddr('l1Wallet'));
        vm.prank(owner);
        splitter.updateL1Recipient(newRecipient);
        assertEq(splitter.l1Recipient(), newRecipient);
    }

    function test_ShouldUpdateFeeDisbursementInterval(uint48 newInterval) public {
        assertEq(splitter.feeDisbursementInterval(), 1 days);
        vm.prank(owner);
        splitter.updateFeeDisbursementInterval(newInterval);
        assertEq(splitter.feeDisbursementInterval(), newInterval);
    }

    function test_ShouldUpdateMinWithdrawalAmount(uint256 newAmount) public {
        assertEq(splitter.minWithdrawalAmount(), 0.1 ether);
        vm.prank(owner);
        splitter.updateMinWithdrawalAmount(newAmount);
        assertEq(splitter.minWithdrawalAmount(), newAmount);
    }

    function test_Withdrawal(uint256 amount) public {
        amount = bound(amount, 0.1 ether + 1, type(uint256).max);
        vm.deal(address(splitter), amount);
        vm.warp(block.timestamp + 1 days + 1);
        vm.expectEmit(true, true, true, true);
        emit IL1Splitter.Withdrawal(makeAddr('l1Wallet'), amount);
        splitter.withdraw();
    }
}

contract MockL2StandardBridge {
    function bridgeETHTo(address, uint32, bytes calldata) external payable {}
}
