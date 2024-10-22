// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import 'forge-std/Test.sol';

import {AttestationRewards} from '../../src/UVN/rewards/AttestationRewards.sol';
import {MockNetFeeSplitter} from '../mock/MockNetFeeSplitter.sol';
import {UVNSetupTest} from './UVNSetup.t.sol';

contract AttestationRewardsTest is UVNSetupTest {
    AttestationRewards internal attestationRewards;
    address internal _attestationRewards;

    MockNetFeeSplitter internal mockNetFeeSplitter;
    address internal _mockNetFeeSplitter;

    uint32 internal epochLength;

    function setUp() public override {
        super.setUp();

        mockNetFeeSplitter = new MockNetFeeSplitter();
        _mockNetFeeSplitter = address(mockNetFeeSplitter);

        attestationRewards = new AttestationRewards(_mockNetFeeSplitter, _delegationManager);
        _attestationRewards = address(attestationRewards);

        vm.prank(_mockL2CrossDomainMessenger);
        stakeManager.sync(alice, 100, '');

        vm.prank(alice);
        delegationManager.delegate(operator);

        epochLength = uint32(attestationRewards.EPOCH_LENGTH());
    }
}
