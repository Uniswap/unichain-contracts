// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import 'forge-std/Test.sol';

import {StakeManager} from '../../src/UVN/StakeManager.sol';

contract StakeManagerTest is Test {
    StakeManager internal stakeManager;
    address internal _stakeManager;

    MockL2CrossDomainMessenger internal mockL2CrossDomainMessenger;
    address internal _mockL2CrossDomainMessenger;

    address internal alice = makeAddr('alice');

    function setUp() public {
        address crossDomainStaker = makeAddr('crossDomainStaker');
        mockL2CrossDomainMessenger = new MockL2CrossDomainMessenger();
        mockL2CrossDomainMessenger.setSender(crossDomainStaker);
        _mockL2CrossDomainMessenger = address(mockL2CrossDomainMessenger);
        
        stakeManager = new StakeManager(_mockL2CrossDomainMessenger, crossDomainStaker);
        _stakeManager = address(stakeManager);
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
