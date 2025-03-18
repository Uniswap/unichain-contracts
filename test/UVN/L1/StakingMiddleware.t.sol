// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {L1TestHandler} from './L1TestHandler.sol';

contract StakingMiddlewareTest is L1TestHandler {
    function setUp() public override {
        super.setUp();
    }

    function test_mint() public {
        stakeToken.mint(address(this), 1000);
        stakeToken.approve(address(stakingMiddleware), 1000);
        stakingMiddleware.stake(1000);
        vm.prank(operator);
        stakingMiddleware.mint();
        vm.prank(operator);
        stakingMiddleware.setDelegationStatus(true);
        stakingMiddleware.delegate(operator);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 1000);
        assertEq(stakingMiddleware.getVotes(operator), 1000);
    }
}
