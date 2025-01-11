// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import 'forge-std/Test.sol';

import {StakeManager} from '../../src/UVN/base/StakeManager.sol';
import {UVNSetupTest} from './UVNSetup.t.sol';

contract StakeManagerTest is UVNSetupTest {
    function setUp() public override {
        super.setUp();
    }

    function test_RevertIf_OnlyCrossDomainStaker() public {
        vm.expectRevert(abi.encodeWithSelector(StakeManager.OnlyCrossDomainStaker.selector));
        stakeManager.sync(address(0), 0, '');
    }

    function test_Sync() public {
        vm.prank(_mockL2CrossDomainMessenger);
        stakeManager.sync(alice, 100, '');

        assertEq(stakeManager.balanceOf(alice), 100);
        assertEq(stakeManager.totalSupply(), 100);
    }
}
