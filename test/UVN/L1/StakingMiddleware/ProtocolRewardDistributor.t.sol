// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IProtocolRewardDistributor,
    ProtocolRewardDistributor
} from '../../../../src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol';
import {UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {IUniStaker, UniStakerDeployer} from '../../../deployers/UniStakerDeployer.sol';

import {L1TestHandler} from '../L1TestHandler.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ProtocolRewardDistributorHarness is ProtocolRewardDistributor {
    constructor(IUniStaker unistaker_, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {}

    function updateGlobalRewardCheckpoint() external {
        _updateGlobalRewardCheckpoint();
    }

    function totalAmountStaked() external view returns (uint96) {
        return _totalAmountDepositedIntoUniStaker();
    }
}

contract ProtocolRewardDistributorTest is L1TestHandler {
    ProtocolRewardDistributorHarness protocolRewardDistributor;

    function setUp() public override {
        super.setUp();
        unistaker.setRewardNotifier(address(this), true);
        protocolRewardDistributor =
            new ProtocolRewardDistributorHarness(unistaker, address(this), 0, slashingBeneficiary);
        // use up the first depositId 0
        unistaker.stake(0, delegatee);
    }

    function _depositor(uint256 i) internal returns (address) {
        return makeAddr(string(abi.encodePacked('depositor', i)));
    }

    function _recipient(uint256 i) internal returns (address) {
        return makeAddr(string(abi.encodePacked('recipient', i)));
    }

    function expectERC20Transfer(address from, address to, uint256 amount) internal {
        vm.expectEmit();
        emit IERC20.Transfer(from, to, amount);
    }

    function _randomUint96(uint256 seed, uint256 index) internal pure returns (uint96) {
        uint96 pseudoRandom = uint96(uint256(keccak256(abi.encodePacked(seed, index))) % type(uint96).max);
        return uint96(bound(uint256(pseudoRandom), 1, 100 ether));
    }

    function test_shouldDistributeRewardsCorrectly(uint256 seed) public {
        uint256 numDepositors = 10;
        uint96[] memory amounts = new uint96[](numDepositors);
        address[] memory depositors = new address[](numDepositors);
        address[] memory recipients = new address[](numDepositors);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < numDepositors; i++) {
            amounts[i] = _randomUint96(seed, i);
            depositors[i] = _depositor(i);
            recipients[i] = _recipient(i);
            stakeToken.mint(depositors[i], amounts[i]);
            vm.startPrank(depositors[i]);
            stakeToken.approve(address(protocolRewardDistributor), amounts[i]);
            protocolRewardDistributor.stake(amounts[i]);
            protocolRewardDistributor.depositIntoUniStaker(delegatee);
            vm.stopPrank();
            totalAmount += amounts[i];
        }
        assertEq(protocolRewardDistributor.totalAmountStaked(), totalAmount);

        uint256 rewardAmount = _randomUint96(seed, numDepositors);
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        // reward duration is 30 days, wait for full amount
        vm.warp(block.timestamp + 30 days);
        assertApproxEqAbs(unistaker.unclaimedReward(address(protocolRewardDistributor)), rewardAmount, 1);
        rewardAmount = unistaker.unclaimedReward(address(protocolRewardDistributor));
        expectERC20Transfer(address(unistaker), address(protocolRewardDistributor), rewardAmount);
        vm.expectEmit(true, true, true, true);
        emit IProtocolRewardDistributor.RewardsAdded(rewardAmount);
        console.log("Expected reward amount:", rewardAmount);
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        for (uint256 i = 0; i < numDepositors; i++) {
            uint256 reward = protocolRewardDistributor.rewardsOf(depositors[i]);
            assertEq(reward, rewardAmount * amounts[i] / totalAmount);
            expectERC20Transfer(address(protocolRewardDistributor), recipients[i], reward);
            vm.expectEmit();
            emit IProtocolRewardDistributor.RewardsWithdrawn(depositors[i], recipients[i], reward);
            vm.prank(depositors[i]);
            uint256 withdrawn = protocolRewardDistributor.withdrawRewards(recipients[i]);
            assertEq(withdrawn, reward);
        }
    }

    // Basic single staker test
    function test_singleStakerRewardDistribution(uint96 stakeAmount, uint96 rewardAmount) public {
        vm.assume(stakeAmount > 0 && stakeAmount <= 100 ether);
        vm.assume(rewardAmount > 1 ether && rewardAmount <= 100 ether);
        
        address depositor = _depositor(1);
        
        // Setup stake
        stakeToken.mint(depositor, stakeAmount);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), stakeAmount);
        protocolRewardDistributor.stake(stakeAmount);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        // Distribute rewards
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        // Reward duration is 30 days, wait for full amount
        vm.warp(block.timestamp + 30 days);
        uint256 expectedReward = unistaker.unclaimedReward(address(protocolRewardDistributor));
        assertApproxEqAbs(expectedReward, rewardAmount, 1);
        
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        
        // Single staker should get the entire reward
        assertApproxEqAbs(expectedReward, protocolRewardDistributor.rewardsOf(depositor), 1);
    }

    // Edge cases
    function test_zeroRewards() public {
        address depositor = _depositor(1);
        uint96 stakeAmount = 1 ether;
        
        stakeToken.mint(depositor, stakeAmount);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), stakeAmount);
        protocolRewardDistributor.stake(stakeAmount);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        // No rewards distributed
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        assertEq(protocolRewardDistributor.rewardsOf(depositor), 0);
    }

    function test_zeroTotalStaked() public {
        uint96 rewardAmount = 1 ether;
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        
        // Record initial checkpoint
        uint256 initialCheckpoint = protocolRewardDistributor.rewardsOf(address(0));
        
        // Should not revert and checkpoint should remain unchanged
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        
        // Verify checkpoint hasn't changed
        assertEq(
            protocolRewardDistributor.rewardsOf(address(0)),
            initialCheckpoint,
            "Global checkpoint should not change when total staked is 0"
        );
        
        // Verify total staked is 0
        assertEq(protocolRewardDistributor.totalAmountStaked(), 0, "Total staked should be 0");
    }

    function test_noTimePassedAfterRewards() public {
        address depositor = _depositor(1);
        uint96 stakeAmount = 1 ether;
        uint96 rewardAmount = 1 ether;
        
        // Setup stake
        stakeToken.mint(depositor, stakeAmount);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), stakeAmount);
        protocolRewardDistributor.stake(stakeAmount);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        // Distribute rewards but don't advance time
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        
        // Update checkpoint immediately
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        
        // Should have no rewards yet since no time has passed
        assertEq(protocolRewardDistributor.rewardsOf(depositor), 0, "Should have no rewards before time passes");
    }

    // Precision tests
    function test_smallAmountPrecision() public {
        uint96 smallStake = 1e9;  // 1 gwei
        uint96 smallReward = 1e9; // 1 gwei
        
        address depositor = _depositor(1);
        
        stakeToken.mint(depositor, smallStake);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), smallStake);
        protocolRewardDistributor.stake(smallStake);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        rewardToken.mint(address(unistaker), smallReward);
        unistaker.notifyRewardAmount(smallReward);
        vm.warp(block.timestamp + 30 days);
        
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        uint256 reward = protocolRewardDistributor.rewardsOf(depositor);
        
        // Allow for minimal precision loss
        assertApproxEqAbs(
            reward,
            smallReward,
            1, // 1 wei tolerance
            "Should handle small amounts with reasonable precision"
        );
        
        // Verify reward is non-zero
        assertGt(reward, 0, "Reward should not round down to zero");
    }

    function test_maxStakeAmount() public {
        uint96 maxStake = type(uint96).max;
        address depositor = _depositor(1);
        
        stakeToken.mint(depositor, maxStake);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), maxStake);
        protocolRewardDistributor.stake(maxStake);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        // Should still handle rewards correctly
        uint96 rewardAmount = 1 ether;
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        vm.warp(block.timestamp + 30 days);
        
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        uint256 reward = protocolRewardDistributor.rewardsOf(depositor);
        // Allow for minimal precision loss
        assertApproxEqAbs(reward, rewardAmount, 100, "Reward amount should match expected amount");
    }

    // Security tests
    function test_preventRewardIsolation() public {
        address depositor = _depositor(1);
        address attacker = _depositor(2);
        uint96 stakeAmount = 1 ether;
        
        // Setup stake and rewards
        stakeToken.mint(depositor, stakeAmount);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), stakeAmount);
        protocolRewardDistributor.stake(stakeAmount);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        rewardToken.mint(address(unistaker), 1 ether);
        unistaker.notifyRewardAmount(1 ether);
        vm.warp(block.timestamp + 30 days);
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        
        // Attempt unauthorized withdrawal
        vm.prank(attacker);
        uint256 withdrawn = protocolRewardDistributor.withdrawRewards(attacker);
        assertEq(withdrawn, 0, "Depositor with no stake shouldn't have any rewards");
    }

    function test_multipleRewardPeriods(uint256 seed) public {
        uint96 stakeAmount = _randomUint96(seed, 0);
        address depositor = _depositor(1);
        address recipient = _recipient(1);
        
        // Initial stake
        stakeToken.mint(depositor, stakeAmount);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), stakeAmount);
        protocolRewardDistributor.stake(stakeAmount);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        uint256 totalRewards = 0;
        
        // Multiple reward periods
        for(uint256 i = 0; i < 3; i++) {
            uint96 rewardAmount = _randomUint96(seed, i + 1);
            rewardToken.mint(address(unistaker), rewardAmount);
            unistaker.notifyRewardAmount(rewardAmount);
            vm.warp(block.timestamp + 30 days);
            
            uint256 unclaimedReward = unistaker.unclaimedReward(address(protocolRewardDistributor));
            if (unclaimedReward > 0) {
                expectERC20Transfer(
                    address(unistaker),
                    address(protocolRewardDistributor),
                    unclaimedReward
                );
                vm.expectEmit(true, true, true, true);
                emit IProtocolRewardDistributor.RewardsAdded(unclaimedReward);
            }
            
            protocolRewardDistributor.updateGlobalRewardCheckpoint();
            totalRewards += unclaimedReward;
        }
        
        uint256 finalReward = protocolRewardDistributor.rewardsOf(depositor);
        assertApproxEqAbs(finalReward, totalRewards, 1, "Should accumulate rewards correctly across periods");

        // Test withdrawal
        expectERC20Transfer(address(protocolRewardDistributor), recipient, finalReward);
        vm.expectEmit();
        emit IProtocolRewardDistributor.RewardsWithdrawn(depositor, recipient, finalReward);
        vm.prank(depositor);
        uint256 withdrawn = protocolRewardDistributor.withdrawRewards(recipient);
        assertApproxEqAbs(withdrawn, finalReward, 1, "Should withdraw accumulated rewards correctly");
    }

    // Lifecycle tests
    function test_halfRewardPeriod() public {
        address depositor = _depositor(1);
        uint96 stakeAmount = 1 ether;
        uint96 rewardAmount = 1 ether;
        
        // Setup stake
        stakeToken.mint(depositor, stakeAmount);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), stakeAmount);
        protocolRewardDistributor.stake(stakeAmount);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        // Distribute rewards
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        
        // Advance time halfway through reward period (15 days)
        vm.warp(block.timestamp + 15 days);
        
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        
        // Should have approximately half the rewards
        uint256 expectedHalfReward = rewardAmount / 2;
        assertApproxEqAbs(
            protocolRewardDistributor.rewardsOf(depositor),
            expectedHalfReward,
            1e15, // Allow for small rounding differences
            "Should have ~50% of rewards after half the period"
        );
    }

    function testFuzz_stakeUnstakeRewardCycle(uint96 initialStake, uint96 additionalStake, uint96 rewardAmount) public {
        vm.assume(initialStake > 1e9 && initialStake <= 50 ether);
        vm.assume(additionalStake > 1e9 && additionalStake <= 50 ether);
        vm.assume(rewardAmount > 1e9 && rewardAmount <= 100 ether);
        
        address depositor = _depositor(1);
        
        // Initial stake
        stakeToken.mint(depositor, initialStake + additionalStake);
        vm.startPrank(depositor);
        stakeToken.approve(address(protocolRewardDistributor), initialStake + additionalStake);
        protocolRewardDistributor.stake(initialStake);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        // First reward period
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        vm.warp(block.timestamp + 15 days);
        
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        uint256 firstReward = protocolRewardDistributor.rewardsOf(depositor);
        
        // Additional stake - need to withdraw first
        vm.startPrank(depositor);
        protocolRewardDistributor.withdrawFromUniStaker();
        protocolRewardDistributor.unstake(initialStake);
        protocolRewardDistributor.stake(additionalStake);
        protocolRewardDistributor.depositIntoUniStaker(delegatee);
        vm.stopPrank();
        
        // Second reward period
        vm.warp(block.timestamp + 15 days);
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        
        uint256 totalReward = protocolRewardDistributor.rewardsOf(depositor);
        assertGt(totalReward, firstReward, "Total reward should be greater than first reward");
    }

    function testFuzz_multipleRewardDeposits(uint256 seed) public {
        uint256 numDepositors = 50;
        uint96[] memory amounts = new uint96[](numDepositors);
        address[] memory depositors = new address[](numDepositors);
        uint256 totalAmount = 0;
        uint256 maxDeltaWei = 10;
        
        // Track rewards like the contract does
        uint256 PRECISION = 1e27;
        uint256 globalRewardCheckpoint;
        
        // Use memory mappings via arrays instead
        uint256[] memory rewardCheckpoints = new uint256[](numDepositors);
        uint256[] memory earnedRewards = new uint256[](numDepositors);

        // Setup initial stakes
        for (uint256 i = 0; i < numDepositors; i++) {
            amounts[i] = _randomUint96(seed, i);
            depositors[i] = _depositor(i);
            stakeToken.mint(depositors[i], amounts[i]);
            vm.startPrank(depositors[i]);
            stakeToken.approve(address(protocolRewardDistributor), amounts[i]);
            protocolRewardDistributor.stake(amounts[i]);
            protocolRewardDistributor.depositIntoUniStaker(delegatee);
            vm.stopPrank();
            totalAmount += amounts[i];
        }

        // Multiple reward deposits
        uint256 numRewardDeposits = 10;

        for (uint256 i = 0; i < numRewardDeposits; i++) {
            uint256 rewardAmount = Math.min(_randomUint96(seed, numDepositors + i), 1 ether);
            rewardToken.mint(address(unistaker), rewardAmount);
            unistaker.notifyRewardAmount(rewardAmount);
            // Advance time partially through reward period
            vm.warp(block.timestamp + 10 days);
            
            uint256 unclaimedReward = unistaker.unclaimedReward(address(protocolRewardDistributor));
            if (unclaimedReward > 0) {  // Only expect transfer if there are rewards
                expectERC20Transfer(
                    address(unistaker),
                    address(protocolRewardDistributor),
                    unclaimedReward
                );
                vm.expectEmit(true, true, true, true);
                emit IProtocolRewardDistributor.RewardsAdded(unclaimedReward);
            }
            console.log("Expected reward amount:", unclaimedReward);
            protocolRewardDistributor.updateGlobalRewardCheckpoint();

            // First calculate the checkpoint increment exactly as the contract does
            uint256 checkpointIncrement = (unclaimedReward * PRECISION) / totalAmount;
            uint256 newGlobalCheckpoint = globalRewardCheckpoint + checkpointIncrement;
            globalRewardCheckpoint = newGlobalCheckpoint;

            // Then calculate rewards exactly as the contract does
            for (uint256 j = 0; j < numDepositors; j++) {
                address depositor = depositors[j];
                uint256 checkpointDelta = newGlobalCheckpoint - rewardCheckpoints[j];
                uint256 pendingReward = (amounts[j] * checkpointDelta) / PRECISION;
                earnedRewards[j] += pendingReward;
                rewardCheckpoints[j] = newGlobalCheckpoint;

                uint256 actualReward = protocolRewardDistributor.rewardsOf(depositor);
                assertApproxEqAbs(
                    actualReward, 
                    earnedRewards[j], 
                    maxDeltaWei,
                    string.concat(
                        "Reward distribution mismatch for depositor ",
                        vm.toString(j),
                        " at distribution ",
                        vm.toString(i)
                    )
                );
            }

            // Random unstaking/staking after each reward distribution
            for (uint256 j = 0; j < numDepositors; j++) {
                address depositor = depositors[j];
                // 50% chance to modify position
                if (uint256(keccak256(abi.encodePacked(seed, i, j))) % 2 == 0) {
                    if (amounts[j] > 0) {
                        // Withdraw everything
                        vm.startPrank(depositor);
                        protocolRewardDistributor.withdrawFromUniStaker();
                        protocolRewardDistributor.unstake(amounts[j]);
                        totalAmount -= amounts[j];
                        amounts[j] = 0;
                        vm.stopPrank();
                    } else {
                        // Stake new random amount
                        uint96 newStakeAmount = _randomUint96(seed, i + j + 100);
                        stakeToken.mint(depositor, newStakeAmount);
                        vm.startPrank(depositor);
                        stakeToken.approve(address(protocolRewardDistributor), newStakeAmount);
                        protocolRewardDistributor.stake(newStakeAmount);
                        protocolRewardDistributor.depositIntoUniStaker(delegatee);
                        vm.stopPrank();
                        
                        // Update tracking for new stake
                        rewardCheckpoints[j] = newGlobalCheckpoint;
                        amounts[j] = newStakeAmount;
                        totalAmount += newStakeAmount;
                    }
                }
            }
        }

        // Final withdrawal check for each depositor
        for (uint256 i = 0; i < numDepositors; i++) {
            address depositor = depositors[i];
            uint256 finalReward = protocolRewardDistributor.rewardsOf(depositor);
            assertApproxEqAbs(finalReward, earnedRewards[i], maxDeltaWei, "Final reward mismatch");
            
            address recipient = _recipient(i);
            expectERC20Transfer(address(protocolRewardDistributor), recipient, finalReward);
            vm.expectEmit();
            emit IProtocolRewardDistributor.RewardsWithdrawn(depositor, recipient, finalReward);
            vm.prank(depositor);
            uint256 withdrawn = protocolRewardDistributor.withdrawRewards(recipient);
            assertApproxEqAbs(withdrawn, finalReward, maxDeltaWei);
        }
    }
}
