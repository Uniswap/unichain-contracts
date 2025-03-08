// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DelegationManager} from '../../../src/UVN/L1/DelegationManager.sol';
import {StakingMiddleware} from '../../../src/UVN/L1/StakingMiddleware.sol';
import {IUniStaker, UniStakerDeployer} from '../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../mock/MockVotesToken.sol';
import {Test} from 'forge-std/Test.sol';

contract StakingMiddlewareTest is Test {
    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    DelegationManager delegationManager;
    StakingMiddleware stakingMiddleware;
    address operator = makeAddr('operator');

    function setUp() public {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        delegationManager = new DelegationManager(address(this));
        stakingMiddleware =
            new StakingMiddleware(address(this), unistaker, 0, makeAddr('slashing beneficiary'), delegationManager);
        delegationManager.transferOwnership(address(stakingMiddleware));
    }

    function test_mint() public {
        stakeToken.mint(address(this), 1000);
        stakeToken.approve(address(stakingMiddleware), 1000);
        stakingMiddleware.deposit(1000);
        stakingMiddleware.selectOperator(operator);
        assertEq(delegationManager.balanceOf(address(this)), 1000);
        assertEq(delegationManager.getVotes(operator), 1000);
    }
}
