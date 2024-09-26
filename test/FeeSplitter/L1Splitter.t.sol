// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {IL1Splitter, L1Splitter} from '../../src/FeeSplitter/L1Splitter.sol';
import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';

contract L1SplitterTest is Test {
    L1Splitter internal splitter;

    function setUp() public {
        splitter = new L1Splitter(makeAddr('l1Wallet'), 1 days);
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

    function test_Withdrawal(uint256 amount) public {
        vm.assume(amount > 0.1 ether);
        vm.deal(address(splitter), amount);
        vm.warp(block.timestamp + 1 days + 1);
        vm.expectEmit(true, true, true, true);
        emit IL1Splitter.Withdrawal(amount);
        splitter.withdraw();
    }
}

contract MockL2StandardBridge {
    function bridgeETHTo(address, uint32, bytes calldata) external payable {}
}
