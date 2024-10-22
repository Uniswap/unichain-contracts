// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import 'forge-std/Test.sol';

import {OperatorData} from '../../src/UVN/base/BaseStructs.sol';
import {UVNSetupTest} from './UVNSetup.t.sol';

contract DelegationManagerTest is UVNSetupTest {
    function setUp() public override {
        super.setUp();

        // sync balances for alice
        vm.prank(_mockL2CrossDomainMessenger);
        stakeManager.sync(alice, 100, '');
    }

    function test_Delegate() public {
        vm.prank(alice);
        delegationManager.delegate(operator);

        assertEq(delegationManager.delegatedTo(alice), operator);
        (uint96 _sharesLast, uint96 _sharesCurrent, uint32 lastSyncedBlock) = delegationManager.operatorData(operator);
        assertEq(_sharesLast, 0);
        assertEq(_sharesCurrent, 100);
        assertEq(lastSyncedBlock, block.number);
        assertEq(delegationManager.totalDelegatedSupply(), 100);
    }

    function test_Undelegate() public {
        vm.prank(alice);
        delegationManager.delegate(operator);

        assertEq(delegationManager.delegatedTo(alice), operator);
        (uint96 _sharesLast, uint96 _sharesCurrent, uint32 lastSyncedBlock) = delegationManager.operatorData(operator);
        assertEq(_sharesLast, 0);
        assertEq(_sharesCurrent, 100);
        assertEq(lastSyncedBlock, block.number);

        assertEq(delegationManager.totalDelegatedSupply(), 100);

        vm.prank(alice);
        delegationManager.undelegate(operator);

        assertEq(delegationManager.delegatedTo(alice), address(0));
        (_sharesLast, _sharesCurrent, lastSyncedBlock) = delegationManager.operatorData(operator);
        assertEq(_sharesLast, 100);
        assertEq(_sharesCurrent, 0);
        assertEq(lastSyncedBlock, block.number);
        assertEq(delegationManager.totalDelegatedSupply(), 0);
    }
}
