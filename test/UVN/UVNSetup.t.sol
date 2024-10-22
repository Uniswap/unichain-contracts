// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import 'forge-std/Test.sol';

import {DelegationManager} from '../../src/UVN/base/DelegationManager.sol';
import {StakeManager} from '../../src/UVN/base/StakeManager.sol';
import {MockL2CrossDomainMessenger} from '../mock/MockL2CrossDomainMessenger.sol';

abstract contract UVNSetupTest is Test {
    StakeManager internal stakeManager;
    address internal _stakeManager;

    DelegationManager internal delegationManager;
    address internal _delegationManager;

    MockL2CrossDomainMessenger internal mockL2CrossDomainMessenger;
    address internal _mockL2CrossDomainMessenger;

    // Actors
    address internal alice = makeAddr('alice');
    address internal bob = makeAddr('bob');
    address internal charlie = makeAddr('charlie');
    address internal operator = makeAddr('operator');

    function setUp() public virtual {
        address crossDomainStaker = makeAddr('crossDomainStaker');
        mockL2CrossDomainMessenger = new MockL2CrossDomainMessenger();
        mockL2CrossDomainMessenger.setSender(crossDomainStaker);
        _mockL2CrossDomainMessenger = address(mockL2CrossDomainMessenger);

        stakeManager = new StakeManager(_mockL2CrossDomainMessenger, crossDomainStaker);
        _stakeManager = address(stakeManager);

        delegationManager = new DelegationManager(_stakeManager);
        _delegationManager = address(delegationManager);

        // Add sanity deploy checks here
    }
}
