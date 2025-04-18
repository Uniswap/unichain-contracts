// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DefaultDelegatorClaim} from '../../../src/UVN/L2/DefaultDelegatorClaim.sol';

import {ExampleOperatorFeeManager} from '../../../src/UVN/L2/examples/ExampleOperatorFeeManager.sol';
import {IDefaultDelegatorClaim} from '../../../src/interfaces/UVN/L2/IDefaultDelegatorClaim.sol';
import {IOperatorFeeManager} from '../../../src/interfaces/UVN/L2/IOperatorFeeManager.sol';

import {Test} from 'forge-std/Test.sol';

import {Strings} from 'lib/openzeppelin-contracts/contracts/utils/Strings.sol';
import {AddressAliasHelper} from 'lib/optimism/packages/contracts-bedrock/src/vendor/AddressAliasHelper.sol';

contract DefaultDelegatorClaimTest is Test {
    DefaultDelegatorClaim delegatorClaim;
    ExampleOperatorFeeManager operatorFeeManager;

    address stakeTable;
    address operator;
    address delegator1;
    address delegator2;

    uint256 constant PERCENTAGE_DENOMINATOR = 1e18;
    uint256 constant OPERATOR_FEE_PERCENTAGE = 1e17; // 10%

    function setUp() public virtual {
        stakeTable = address(this);
        operator = makeAddr('operator');
        delegator1 = makeAddr('delegator1');
        delegator2 = makeAddr('delegator2');

        delegatorClaim = new DefaultDelegatorClaim(operator);
        operatorFeeManager = new ExampleOperatorFeeManager(operator, OPERATOR_FEE_PERCENTAGE);

        // Setup initial delegator stakes
        vm.prank(stakeTable);
        delegatorClaim.reportDelegatorStake(delegator1, 50 ether);

        vm.prank(stakeTable);
        delegatorClaim.reportDelegatorStake(delegator2, 50 ether);
    }

    function test_constructor() public {
        assertEq(delegatorClaim.OPERATOR(), operator);
        assertEq(delegatorClaim.totalDelegation(), 100 ether);
        assertEq(delegatorClaim.delegationOf(delegator1), 50 ether);
        assertEq(delegatorClaim.delegationOf(delegator2), 50 ether);
    }

    function test_reportDelegatorStake() public {
        address noob = makeAddr('noob');

        // Add a new delegator
        vm.prank(stakeTable);
        delegatorClaim.reportDelegatorStake(noob, 25 ether);

        // Check total delegation and individual delegations
        assertEq(delegatorClaim.totalDelegation(), 125 ether);
        assertEq(delegatorClaim.delegationOf(noob), 25 ether);

        // Update an existing delegator (increase)
        vm.prank(stakeTable);
        delegatorClaim.reportDelegatorStake(delegator1, 75 ether);

        assertEq(delegatorClaim.totalDelegation(), 150 ether);
        assertEq(delegatorClaim.delegationOf(delegator1), 75 ether);

        // Decrease an existing stake
        vm.prank(stakeTable);
        delegatorClaim.reportDelegatorStake(delegator2, 25 ether);

        assertEq(delegatorClaim.totalDelegation(), 125 ether);
        assertEq(delegatorClaim.delegationOf(delegator2), 25 ether);
    }

    function test_reportDelegatorStake_onlyStakeTable() public {
        vm.prank(operator);
        vm.expectRevert(IDefaultDelegatorClaim.NotStakeTable.selector);
        delegatorClaim.reportDelegatorStake(delegator1, 100 ether);

        vm.prank(delegator1);
        vm.expectRevert(IDefaultDelegatorClaim.NotStakeTable.selector);
        delegatorClaim.reportDelegatorStake(delegator1, 100 ether);
    }

    function test_setOperatorFeeManager() public {
        vm.prank(operator);
        delegatorClaim.setOperatorFeeManager(operatorFeeManager);

        assertEq(address(delegatorClaim.operatorFeeManager()), address(operatorFeeManager));
    }

    function test_setOperatorFeeManager_onlyOperator() public {
        vm.prank(stakeTable);
        vm.expectRevert(IDefaultDelegatorClaim.NotOperator.selector);
        delegatorClaim.setOperatorFeeManager(operatorFeeManager);

        vm.prank(delegator1);
        vm.expectRevert(IDefaultDelegatorClaim.NotOperator.selector);
        delegatorClaim.setOperatorFeeManager(operatorFeeManager);
    }

    function test_rewardsDistribution_withoutOperatorFee() public {
        // Send rewards to the contract
        vm.deal(address(this), 10 ether);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
        assertTrue(success);

        // Check rewards for each delegator (50% each)
        assertEq(delegatorClaim.rewardsOf(delegator1), 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 5 ether);
    }

    function test_rewardsDistribution_withOperatorFee() public {
        // Set operator fee manager
        vm.prank(operator);
        delegatorClaim.setOperatorFeeManager(operatorFeeManager);

        // Send rewards to the contract
        vm.deal(address(this), 10 ether);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
        assertTrue(success);

        // 10% operator fee = 1 ether
        // Remaining 9 ether split 50/50
        assertEq(delegatorClaim.rewardsOf(delegator1), 4.5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 4.5 ether);

        // Check operator balance
        assertEq(operator.balance, 1 ether);
    }

    function test_rewardsDistribution_noDelegations() public {
        // Clear all delegations
        vm.startPrank(stakeTable);
        delegatorClaim.reportDelegatorStake(delegator1, 0);
        delegatorClaim.reportDelegatorStake(delegator2, 0);
        vm.stopPrank();

        // Try to send rewards (should revert)
        vm.deal(address(this), 10 ether);
        vm.expectRevert(IDefaultDelegatorClaim.NoDelegations.selector);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
    }

    function test_claimRewards() public {
        // Send initial rewards
        vm.deal(address(this), 10 ether);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
        assertTrue(success);

        // Claim rewards for delegator1
        vm.prank(delegator1);
        delegatorClaim.claimRewards(delegator1, delegator1);

        // Verify rewards were claimed
        assertEq(delegator1.balance, 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator1), 0);

        // Claim rewards for delegator2 but send to a different address
        address recipient = makeAddr('recipient');
        vm.prank(delegator2);
        delegatorClaim.claimRewards(delegator2, recipient);

        // Verify rewards were claimed and sent to recipient
        assertEq(recipient.balance, 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 0);
    }

    function test_claimRewards_onlyDelegator() public {
        // Send initial rewards
        vm.deal(address(this), 10 ether);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
        assertTrue(success);

        // Try to claim rewards as non-delegator
        vm.prank(operator);
        vm.expectRevert(IDefaultDelegatorClaim.NotDelegator.selector);
        delegatorClaim.claimRewards(delegator1, operator);
    }

    function test_claimRewards_l1Alias() public {
        // Send initial rewards
        vm.deal(address(this), 10 ether);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
        assertTrue(success);

        // Get L1 to L2 alias of the delegator
        address aliasedAddress = AddressAliasHelper.applyL1ToL2Alias(delegator1);

        // Claim rewards as aliased address
        vm.prank(aliasedAddress);
        delegatorClaim.claimRewards(delegator1, delegator1);

        // Verify rewards were claimed
        assertEq(delegator1.balance, 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator1), 0);
    }

    function test_accumulatingRewards() public {
        // Send initial rewards
        vm.deal(address(this), 5 ether);
        (bool success,) = address(delegatorClaim).call{value: 5 ether}('');
        assertTrue(success);

        // Each delegator should have 2.5 ether in rewards
        assertEq(delegatorClaim.rewardsOf(delegator1), 2.5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 2.5 ether);

        // Send more rewards
        vm.deal(address(this), 5 ether);
        (success,) = address(delegatorClaim).call{value: 5 ether}('');
        assertTrue(success);

        // Each delegator should now have 5 ether in total rewards
        assertEq(delegatorClaim.rewardsOf(delegator1), 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 5 ether);
    }

    function test_rewardsAfterDelegationChange() public {
        // Send initial rewards
        vm.deal(address(this), 10 ether);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
        assertTrue(success);

        // Each delegator should have 5 ether in rewards
        assertEq(delegatorClaim.rewardsOf(delegator1), 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 5 ether);

        // Change delegator stakes
        vm.prank(stakeTable);
        delegatorClaim.reportDelegatorStake(delegator1, 75 ether);

        vm.prank(stakeTable);
        delegatorClaim.reportDelegatorStake(delegator2, 25 ether);

        // Rewards before the change should still be 5 ether each
        assertEq(delegatorClaim.rewardsOf(delegator1), 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 5 ether);

        // Send more rewards (10 ether)
        vm.deal(address(this), 10 ether);
        (success,) = address(delegatorClaim).call{value: 10 ether}('');
        assertTrue(success);

        // New rewards should be distributed 75%/25%
        // delegator1: 5 (previous) + 7.5 (new) = 12.5 ether
        // delegator2: 5 (previous) + 2.5 (new) = 7.5 ether
        assertEq(delegatorClaim.rewardsOf(delegator1), 12.5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 7.5 ether);
    }

    function test_invalidOperatorFee() public {
        MaliciousOperatorFeeManager maliciousFeeManager = new MaliciousOperatorFeeManager(operator, 1e18 + 1);

        // Set the malicious fee manager
        vm.prank(operator);
        delegatorClaim.setOperatorFeeManager(maliciousFeeManager);

        // Try to send rewards (should revert)
        vm.deal(address(this), 10 ether);
        vm.expectRevert(IDefaultDelegatorClaim.OperatorFeeExceedsReward.selector);
        (bool success,) = address(delegatorClaim).call{value: 10 ether}('');
    }

    function testFuzz_rewardDistribution(uint256 rewardAmount) public {
        rewardAmount = bound(rewardAmount, 1 gwei, 1e36);

        // Send rewards to the contract
        vm.deal(address(this), rewardAmount);
        (bool success,) = address(delegatorClaim).call{value: rewardAmount}('');
        assertTrue(success);

        // Check rewards for each delegator (50% each)
        uint256 expectedRewardPerDelegator = rewardAmount / 2;
        assertApproxEqAbs(delegatorClaim.rewardsOf(delegator1), expectedRewardPerDelegator, 1);
        assertApproxEqAbs(delegatorClaim.rewardsOf(delegator2), expectedRewardPerDelegator, 1);

        // Total rewards should equal the reward amount
        assertApproxEqAbs(
            delegatorClaim.rewardsOf(delegator1) + delegatorClaim.rewardsOf(delegator2),
            rewardAmount,
            1 // Allow 1 wei rounding error in total
        );
    }

    function testFuzz_rewardDistributionWithFee(uint256 rewardAmount, uint256 feePercentage) public {
        rewardAmount = bound(rewardAmount, 1 gwei, 1e36);
        feePercentage = bound(feePercentage, 0, 1e18);

        // Deploy fee manager with specified percentage
        ExampleOperatorFeeManager customFeeManager = new ExampleOperatorFeeManager(operator, feePercentage);

        // Set the custom fee manager
        vm.prank(operator);
        delegatorClaim.setOperatorFeeManager(customFeeManager);

        // Send rewards to the contract
        vm.deal(address(this), rewardAmount);
        (bool success,) = address(delegatorClaim).call{value: rewardAmount}('');
        assertTrue(success);

        // Calculate expected fee and remaining rewards
        uint256 expectedFee = (rewardAmount * feePercentage) / PERCENTAGE_DENOMINATOR;
        uint256 expectedRemainingRewards = rewardAmount - expectedFee;
        uint256 expectedRewardPerDelegator = expectedRemainingRewards / 2;

        // Check rewards for each delegator
        assertApproxEqAbs(delegatorClaim.rewardsOf(delegator1), expectedRewardPerDelegator, 1);
        assertApproxEqAbs(delegatorClaim.rewardsOf(delegator2), expectedRewardPerDelegator, 1);

        // Check total rewards + operator fee
        assertApproxEqAbs(
            delegatorClaim.rewardsOf(delegator1) + delegatorClaim.rewardsOf(delegator2) + expectedFee,
            rewardAmount,
            1 // Allow 1 wei rounding error in total
        );

        // Check operator balance
        assertEq(operator.balance, expectedFee);
    }

    function testFuzz_delegationGames(uint256 stake1, uint256 stake2, uint256 rewardAmount) public {
        stake1 = bound(stake1, 0, 500_000_000 ether);
        stake2 = bound(stake2, 0, 500_000_000 ether);
        rewardAmount = bound(rewardAmount, 1 gwei, 1_000_000_000 ether);

        uint256[] memory delegatorStakes = new uint256[](50);
        uint256 totalStake = delegatorClaim.totalDelegation();

        // Create 50 delegators with one of the above stakes
        vm.startPrank(stakeTable);
        for (uint256 i = 0; i < 50; i++) {
            address delegator = makeAddr(Strings.toString(i));
            delegatorStakes[i] = i % 2 == 0 ? stake1 : stake2;
            totalStake += delegatorStakes[i];
            delegatorClaim.reportDelegatorStake(delegator, delegatorStakes[i]);
        }
        vm.stopPrank();

        // Check total delegation
        assertEq(delegatorClaim.totalDelegation(), totalStake);

        // Send rewards
        vm.deal(address(this), rewardAmount);
        (bool success,) = address(delegatorClaim).call{value: rewardAmount}('');
        assertTrue(success);

        // Verify rewards are paid out correctly, should never be more than 1 wei off
        for (uint256 i = 0; i < 50; i++) {
            uint256 expectedReward = (rewardAmount * delegatorStakes[i]) / totalStake;
            assertApproxEqAbs(delegatorClaim.rewardsOf(makeAddr(Strings.toString(i))), expectedReward, 1);
        }
    }

    receive() external payable {}
}

contract MaliciousOperatorFeeManager is IOperatorFeeManager {
    address public immutable OPERATOR;
    uint256 public immutable rewardMultiplier;

    constructor(address operator_, uint256 rewardMultiplier_) {
        OPERATOR = operator_;
        rewardMultiplier = rewardMultiplier_;
    }

    function operatorFee(uint256 reward) external view returns (uint256) {
        return reward * rewardMultiplier / 1e18;
    }

    receive() external payable {
        (bool sent,) = OPERATOR.call{value: msg.value}('');
        require(sent, 'Failed to send ETH to operator');
    }
}
