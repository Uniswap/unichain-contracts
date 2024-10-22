// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import 'forge-std/Test.sol';

import {OperatorData} from '../../src/UVN/base/BaseStructs.sol';
import {DelegationManager} from '../../src/UVN/base/DelegationManager.sol';
import {StakeManager} from '../../src/UVN/base/StakeManager.sol';
import {MockL2CrossDomainMessenger} from '../mock/MockL2CrossDomainMessenger.sol';

contract DelegationManagerTest is Test {
    DelegationManager internal delegationManager;
    address internal _delegationManager;

    StakeManager internal stakeManager;
    address internal _stakeManager;

    MockL2CrossDomainMessenger internal mockL2CrossDomainMessenger;
    address internal _mockL2CrossDomainMessenger;

    address internal alice = makeAddr('alice');
    address internal operator = makeAddr('operator');

    function setUp() public {
        address crossDomainStaker = makeAddr('crossDomainStaker');
        mockL2CrossDomainMessenger = new MockL2CrossDomainMessenger();
        mockL2CrossDomainMessenger.setSender(crossDomainStaker);
        _mockL2CrossDomainMessenger = address(mockL2CrossDomainMessenger);

        stakeManager = new StakeManager(_mockL2CrossDomainMessenger, crossDomainStaker);
        _stakeManager = address(stakeManager);

        delegationManager = new DelegationManager(_stakeManager);
        _delegationManager = address(delegationManager);

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
