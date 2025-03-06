// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DelegationManager} from '../../../src/UVN/L1/DelegationManager.sol';
import {StakingMiddleware} from '../../../src/UVN/L1/StakingMiddleware.sol';
import {IUniStaker, UniStakerDeployer} from '../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../mock/MockVotesToken.sol';
import {Test} from 'forge-std/Test.sol';

contract StakingMiddlewareSlashingTest is Test {
    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    DelegationManager delegationManager;
    StakingMiddleware stakingMiddleware;
    address operator = makeAddr('operator');
    address slasher = makeAddr('slasher');

    function setUp() public {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        delegationManager = new DelegationManager(address(this));
        stakingMiddleware = new StakingMiddleware(address(this), unistaker, 0, delegationManager);
        delegationManager.transferOwnership(address(stakingMiddleware));
        stakingMiddleware.grantRole(stakingMiddleware.SLASHER_ROLE(), slasher);
    }

    function deposit(address user, uint96 amount) public {
        stakeToken.mint(user, amount);
        vm.prank(user);
        stakeToken.approve(address(stakingMiddleware), amount);
        vm.prank(user);
        stakingMiddleware.deposit(amount);
    }

    function test_slash() public {
        deposit(address(this), 1000);
        stakingMiddleware.selectOperator(operator);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 1000);
        assertEq(stakingMiddleware.totalOperatorStake(operator), 1000);
        vm.prank(slasher);
        stakingMiddleware.slashAmount(operator, 100);
        assertEq(stakingMiddleware.totalOperatorStake(operator), 900);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 900);
        vm.prank(slasher);
        stakingMiddleware.slashPercentage(operator, 0.5e18);
        assertEq(stakingMiddleware.totalOperatorStake(operator), 450);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 450);
        stakingMiddleware.applySlashing(address(this), 2);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 450);
    }
}
