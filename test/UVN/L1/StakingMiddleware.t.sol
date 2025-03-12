// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakingMiddleware} from '../../../src/UVN/L1/StakingMiddleware.sol';
import {IUniStaker, UniStakerDeployer} from '../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../mock/MockVotesToken.sol';
import {Test} from 'forge-std/Test.sol';

contract StakingMiddlewareTest is Test {
    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    StakingMiddleware stakingMiddleware;
    address operator = makeAddr('operator');

    function setUp() public {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        stakingMiddleware = new StakingMiddleware(unistaker, address(this), 0, makeAddr('slashing beneficiary'));
    }

    function test_mint() public {
        stakeToken.mint(address(this), 1000);
        stakeToken.approve(address(stakingMiddleware), 1000);
        stakingMiddleware.stake(1000);
        stakingMiddleware.delegate(operator);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 1000);
        assertEq(stakingMiddleware.getVotes(operator), 1000);
    }
}
