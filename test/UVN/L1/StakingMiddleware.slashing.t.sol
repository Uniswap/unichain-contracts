// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakingMiddleware} from '../../../src/UVN/L1/StakingMiddleware.sol';
import {IUniStaker, UniStakerDeployer} from '../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../mock/MockVotesToken.sol';
import 'forge-std/Test.sol';

contract StakingMiddlewareSlashingTest is Test {
    uint256 private constant REWARD_DURATION = 30 days;
    uint96 private constant DEFAULT_REWARD = 1 ether;

    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    StakingMiddleware stakingMiddleware;
    address operator = makeAddr('operator');
    address slasher = makeAddr('slasher');
    address slashingBeneficiary = makeAddr('slashing beneficiary');

    function setUp() public {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        stakingMiddleware = new StakingMiddleware(unistaker, address(this), 0, slashingBeneficiary);
        stakingMiddleware.grantRole(stakingMiddleware.SLASHER_ROLE(), slasher);
        unistaker.setRewardNotifier(address(this), true);
        unistaker.stake(0, operator);
    }

    function depositRewardsIntoUnistaker(uint96 amount) public returns (uint256 actualReward) {
        uint256 initialReward = unistaker.unclaimedReward(address(stakingMiddleware));
        rewardToken.mint(address(unistaker), amount);
        unistaker.notifyRewardAmount(amount);
        vm.warp(block.timestamp + REWARD_DURATION);
        actualReward = unistaker.unclaimedReward(address(stakingMiddleware)) - initialReward;
    }

    function deposit(address user, uint96 amount) public {
        stakeToken.mint(user, amount);
        vm.prank(user);
        stakeToken.approve(address(stakingMiddleware), amount);
        vm.prank(user);
        stakingMiddleware.stake(amount);
    }

    function test_slash() public {
        deposit(address(this), 1000);
        stakingMiddleware.depositIntoUniStaker(address(this));
        vm.prank(operator);
        stakingMiddleware.setDelegationStatus(true);
        stakingMiddleware.delegate(operator);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 1000, 'delegator stake does not match');
        assertEq(stakingMiddleware.getVotes(operator), 1000, 'total operator stake does not match');
        uint256 reward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        uint256 totalRewardWithoutSlashing = reward;
        uint256 totalReward = totalRewardWithoutSlashing;
        assertEq(stakingMiddleware.rewardsOf(address(this)), totalReward, 'rewards do not match');
        vm.prank(slasher);
        stakingMiddleware.slashAmount(operator, 100);
        uint256 nextReward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        totalRewardWithoutSlashing += nextReward;
        totalReward += nextReward * 900 / 1000;
        assertEq(stakingMiddleware.getVotes(operator), 900);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 900);
        assertEq(stakingMiddleware.rewardsOf(address(this)), totalReward, 'rewards do not match after slashing');
        vm.prank(slasher);
        stakingMiddleware.slashPercentage(operator, 0.5e18);
        nextReward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        totalRewardWithoutSlashing += nextReward;
        totalReward += nextReward * 450 / 1000;
        assertEq(stakingMiddleware.getVotes(operator), 450);
        assertEq(stakingMiddleware.delegatorStake(address(this)), 450);
        assertEq(stakingMiddleware.rewardsOf(address(this)), totalReward, 'rewards do not match after second slashing');
        stakingMiddleware.applySlashing(address(this), 1);
        stakingMiddleware.applySlashing(address(this), 1);
        assertEq(stakeToken.balanceOf(slashingBeneficiary), 550, 'slashing beneficiary stake does not match');
        assertEq(
            rewardToken.balanceOf(slashingBeneficiary),
            totalRewardWithoutSlashing - totalReward,
            'slashing beneficiary reward does not match'
        );
        assertEq(stakingMiddleware.delegatorStake(address(this)), 450);
        assertEq(
            stakingMiddleware.rewardsOf(address(this)), totalReward, 'rewards do not match after applying slashing'
        );
        uint256 actualReward = stakingMiddleware.withdrawRewards(address(this));
        assertEq(actualReward, totalReward, 'actual reward does not match shown rewards');
    }
}
