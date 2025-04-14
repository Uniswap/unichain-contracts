// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ISlashingManager, SlashingManager} from '../../../../src/UVN/L1/StakingMiddleware/SlashingManager.sol';

import {IOperatorManager, OperatorManager} from '../../../../src/UVN/L1/StakingMiddleware/OperatorManager.sol';
import {IUniStaker, UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {L1TestHandler} from '../L1TestHandler.sol';

contract SlashingManagerHarness is SlashingManager {
    constructor(IUniStaker unistaker_, address initialAdmin, address slashingBeneficiary_)
        UniStakerWrapper(unistaker_, initialAdmin, 0, slashingBeneficiary_)
        OperatorManager('UVN Staking Middleware')
    {}

    function isDelegatorSlashed(address delegator) public view returns (bool) {
        address operator = _slashableOperatorOf(delegator);
        uint256 nextDelegatorInstance = _delegatorNextSlashingInstance[delegator];
        uint256 operatorLength = _slashingInstances[operator].length;
        return _isDelegatorSlashed(nextDelegatorInstance, operatorLength);
    }
}

contract StakingMiddlewareSlashingTest is L1TestHandler {
    uint256 private constant REWARD_DURATION = 30 days;
    uint96 private constant DEFAULT_REWARD = 1 ether;
    uint96 private constant DEFAULT_STAKE = 1000 ether;

    SlashingManagerHarness slashingManager;

    function setUp() public override {
        super.setUp();
        slashingManager = new SlashingManagerHarness(unistaker, address(this), slashingBeneficiary);
        slashingManager.grantRole(slashingManager.SLASHER_ROLE(), slasher);
        unistaker.setRewardNotifier(address(this), true);
        unistaker.stake(0, operator);
    }

    function depositRewardsIntoUnistaker(uint96 amount) public returns (uint256 actualReward) {
        uint256 initialReward = unistaker.unclaimedReward(address(slashingManager));
        rewardToken.mint(address(unistaker), amount);
        unistaker.notifyRewardAmount(amount);
        vm.warp(block.timestamp + REWARD_DURATION);
        actualReward = unistaker.unclaimedReward(address(slashingManager)) - initialReward;
    }

    function deposit(address user, uint96 amount) public {
        stakeToken.mint(user, amount);
        vm.startPrank(user);
        stakeToken.approve(address(slashingManager), amount);
        slashingManager.stake(amount);
        vm.stopPrank();
    }

    function depositAndDelegate(address user, uint96 amount) public {
        deposit(user, amount);
        vm.prank(operator);
        slashingManager.setDelegationStatus(true);
        vm.prank(user);
        slashingManager.delegate(operator);
    }

    function slashOperator() internal {
        vm.prank(slasher);
        slashingManager.slashPercentage(operator, 1);
        assertTrue(slashingManager.isDelegatorSlashed(delegator), 'delegator should be slashed');
    }

    function test_RevertIf_SlashAmountZero() public {
        vm.startPrank(slasher);
        vm.expectRevert(abi.encodeWithSelector(ISlashingManager.SlashingAmountZero.selector));
        slashingManager.slashAmount(operator, 0);
        vm.expectRevert(abi.encodeWithSelector(ISlashingManager.SlashingAmountZero.selector));
        slashingManager.slashPercentage(operator, 0);
        vm.stopPrank();
    }

    function test_RevertIf_SlashPercentageTooHigh(uint96 slashedPercentage) public {
        slashedPercentage = uint96(bound(slashedPercentage, 1e18 + 1, type(uint96).max));
        vm.startPrank(slasher);
        vm.expectRevert(abi.encodeWithSelector(ISlashingManager.SlashingPercentageTooHigh.selector));
        slashingManager.slashPercentage(operator, slashedPercentage);
        vm.stopPrank();
    }

    function test_shouldBeAbleToSlashAmount(uint256 slashedAmount) public {
        uint256 stakedAmount = DEFAULT_STAKE;
        slashedAmount = bound(slashedAmount, 1, stakedAmount);
        uint256 remainingPercentage = (stakedAmount - slashedAmount) * 1e18 / stakedAmount;
        depositAndDelegate(delegator, uint96(stakedAmount));
        vm.prank(slasher);
        vm.expectEmit();
        emit IOperatorManager.OperatorSlashed(operator, uint96(remainingPercentage));
        slashingManager.slashAmount(operator, uint96(slashedAmount));
        assertEq(
            slashingManager.getVotes(operator),
            stakedAmount * remainingPercentage / 1e18,
            'total operator stake does not match after slashing'
        );
    }

    function test_slashMaximumIfAmountIsGreaterThanOperatorStake(uint96 slashedAmount) public {
        uint256 stakedAmount = DEFAULT_STAKE;
        slashedAmount = uint96(bound(slashedAmount, stakedAmount + 1, type(uint96).max));
        depositAndDelegate(delegator, uint96(stakedAmount));
        vm.prank(slasher);
        slashingManager.slashAmount(operator, slashedAmount);
        assertEq(slashingManager.getVotes(operator), 0, 'total operator stake does not match after slashing');
    }

    function test_shouldBeAbleToSlashPercentage(uint256 slashedPercentage) public {
        uint256 stakedAmount = DEFAULT_STAKE;
        slashedPercentage = bound(slashedPercentage, 1, 1e18);
        uint256 remainingPercentage = 1e18 - slashedPercentage;
        depositAndDelegate(delegator, uint96(stakedAmount));
        vm.prank(slasher);
        vm.expectEmit();
        emit IOperatorManager.OperatorSlashed(operator, uint96(remainingPercentage));
        slashingManager.slashPercentage(operator, uint96(slashedPercentage));
        assertEq(
            slashingManager.getVotes(operator),
            stakedAmount * remainingPercentage / 1e18,
            'total operator stake does not match after slashing'
        );
    }

    function test_shouldSlashBeforeStaking() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        slashOperator();
        stakeToken.mint(delegator, 1000);
        vm.startPrank(delegator);
        stakeToken.approve(address(slashingManager), 1000);
        slashingManager.stake(1000);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldSlashBeforeUnstaking() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        slashOperator();
        vm.prank(delegator);
        slashingManager.unstake(1000);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldSlashBeforeWithdrawing() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        vm.prank(delegator);
        slashingManager.unstake(1000);
        slashOperator();
        vm.prank(delegator);
        slashingManager.withdraw(delegator, 1);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldSlashBeforeDepositingIntoUniStaker() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        slashOperator();
        vm.prank(delegator);
        slashingManager.depositIntoUniStaker(delegator);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldSlashBeforeWithdrawingFromUniStaker() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        vm.prank(delegator);
        slashingManager.depositIntoUniStaker(delegator);
        slashOperator();
        vm.prank(delegator);
        slashingManager.withdrawFromUniStaker();
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldSlashBeforeChangingGovernanceDelegatee() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        vm.prank(delegator);
        slashingManager.depositIntoUniStaker(delegator);
        slashOperator();
        vm.prank(delegator);
        slashingManager.alterGovernanceDelegatee(operator);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldSlashBeforeWithdrawingRewards() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        vm.prank(delegator);
        slashingManager.depositIntoUniStaker(delegator);
        slashOperator();
        vm.prank(delegator);
        slashingManager.withdrawRewards(delegator);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldSlashBeforeAnnouncingUndelegation() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        uint256 balanceBefore = slashingManager.delegatorStake(delegator);
        slashOperator();
        vm.prank(delegator);
        slashingManager.announceOperatorUndelegation();
        uint256 balanceAfter = slashingManager.delegatorStake(delegator);
        assertLt(balanceAfter, balanceBefore, 'delegator stake should be slashed');
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_shouldNotBeSlashedIfSlashingAfterUndelegation() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        vm.startPrank(delegator);
        slashingManager.announceOperatorUndelegation();
        slashingManager.delegate(address(0));
        vm.stopPrank();
        uint256 balanceBefore = slashingManager.delegatorStake(delegator);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'delegator should not be slashed');
        vm.prank(slasher);
        slashingManager.slashPercentage(operator, 1);
        uint256 balanceAfter = slashingManager.delegatorStake(delegator);
        assertEq(balanceAfter, balanceBefore, 'delegator stake should not change');
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'delegator should not be slashed after undelegation');
    }

    function test_shouldSlashBeforeUndelegating() public {
        depositAndDelegate(delegator, DEFAULT_STAKE);
        vm.prank(delegator);
        slashingManager.announceOperatorUndelegation();
        slashOperator();
        vm.prank(delegator);
        slashingManager.delegate(address(0));
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'slashing should be applied');
    }

    function test_slashPartialSlashing() public {
        depositAndDelegate(delegator, 1000);
        vm.prank(delegator);
        slashingManager.depositIntoUniStaker(delegator);
        assertEq(slashingManager.delegatorStake(delegator), 1000, 'delegator stake does not match');
        assertEq(slashingManager.getVotes(operator), 1000, 'total operator stake does not match');
        uint256 reward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        uint256 totalRewardWithoutSlashing = reward;
        uint256 totalReward = totalRewardWithoutSlashing;
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match');
        vm.prank(slasher);
        slashingManager.slashAmount(operator, 100);
        uint256 nextReward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        totalRewardWithoutSlashing += nextReward;
        totalReward += nextReward * 900 / 1000;
        assertEq(slashingManager.getVotes(operator), 900);
        assertEq(slashingManager.delegatorStake(delegator), 900);
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match after slashing');
        vm.prank(slasher);
        slashingManager.slashPercentage(operator, 0.5e18);
        nextReward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        totalRewardWithoutSlashing += nextReward;
        totalReward += nextReward * 450 / 1000;
        assertEq(slashingManager.getVotes(operator), 450);
        assertEq(slashingManager.delegatorStake(delegator), 450);
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match after second slashing');
        slashingManager.applySlashing(delegator, 1);
        assertTrue(slashingManager.isDelegatorSlashed(delegator), 'slashing instances should be left to apply');
        slashingManager.applySlashing(delegator, 1);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'all slashing instances should be applied');
        assertEq(stakeToken.balanceOf(slashingBeneficiary), 550, 'slashing beneficiary stake does not match');
        assertEq(
            rewardToken.balanceOf(slashingBeneficiary),
            totalRewardWithoutSlashing - totalReward,
            'slashing beneficiary reward does not match'
        );
        assertEq(slashingManager.delegatorStake(delegator), 450);
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match after applying slashing');
        vm.prank(delegator);
        uint256 actualReward = slashingManager.withdrawRewards(delegator);
        assertEq(actualReward, totalReward, 'actual reward does not match shown rewards');
    }

    function test_slashFullSlashing() public {
        depositAndDelegate(delegator, 1000);
        vm.prank(delegator);
        slashingManager.depositIntoUniStaker(delegator);
        assertEq(slashingManager.delegatorStake(delegator), 1000, 'delegator stake does not match');
        assertEq(slashingManager.getVotes(operator), 1000, 'total operator stake does not match');
        uint256 reward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        uint256 totalRewardWithoutSlashing = reward;
        uint256 totalReward = totalRewardWithoutSlashing;
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match');
        vm.prank(slasher);
        slashingManager.slashAmount(operator, 100);
        uint256 nextReward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        totalRewardWithoutSlashing += nextReward;
        totalReward += nextReward * 900 / 1000;
        assertEq(slashingManager.getVotes(operator), 900);
        assertEq(slashingManager.delegatorStake(delegator), 900);
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match after slashing');
        vm.prank(slasher);
        slashingManager.slashPercentage(operator, 0.5e18);
        nextReward = depositRewardsIntoUnistaker(DEFAULT_REWARD);
        totalRewardWithoutSlashing += nextReward;
        totalReward += nextReward * 450 / 1000;
        assertEq(slashingManager.getVotes(operator), 450);
        assertEq(slashingManager.delegatorStake(delegator), 450);
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match after second slashing');
        slashingManager.applySlashing(delegator, 2);
        assertFalse(slashingManager.isDelegatorSlashed(delegator), 'all slashing instances should be applied');
        assertEq(stakeToken.balanceOf(slashingBeneficiary), 550, 'slashing beneficiary stake does not match');
        assertEq(
            rewardToken.balanceOf(slashingBeneficiary),
            totalRewardWithoutSlashing - totalReward,
            'slashing beneficiary reward does not match'
        );
        assertEq(slashingManager.delegatorStake(delegator), 450);
        assertEq(slashingManager.rewardsOf(delegator), totalReward, 'rewards do not match after applying slashing');
        vm.prank(delegator);
        uint256 actualReward = slashingManager.withdrawRewards(delegator);
        assertEq(actualReward, totalReward, 'actual reward does not match shown rewards');
    }
}
