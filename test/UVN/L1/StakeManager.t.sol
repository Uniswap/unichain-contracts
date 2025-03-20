// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakeManager} from '../../../src/UVN/L1/StakingMiddleware/StakeManager.sol';
import {IStakeManager} from '../../../src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol';
import {L1TestHandler} from './L1TestHandler.sol';

/// @notice Wrapper around StakeManager to test it in isolation
contract StakeManagerTestHarness is StakeManager {
    constructor(address stakeToken, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        StakeManager(stakeToken, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {}

    /// @notice Helper function to test the internal _slashDelegatorStake function
    function slashDelegatorStake(address delegator, uint256 remainingPercentage) external {
        _slashDelegatorStake(delegator, remainingPercentage);
    }
}

contract StakeManagerTest is L1TestHandler {
    StakeManagerTestHarness stakeManager;
    uint256 constant WITHDRAWAL_DELAY = 7 days;

    address initialAdmin = makeAddr('initial admin');
    address delegator = makeAddr('delegator');

    function setUp() public override {
        super.setUp();
        stakeManager =
            new StakeManagerTestHarness(address(stakeToken), initialAdmin, WITHDRAWAL_DELAY, slashingBeneficiary);
    }

    function test_stake() public {
        uint96 amount = 1000;

        // Setup
        stakeToken.mint(delegator, amount);
        vm.prank(delegator);
        stakeToken.approve(address(stakeManager), amount);

        // Execute
        vm.prank(delegator);
        stakeManager.stake(amount);

        // Verify
        assertEq(stakeManager.delegatorStake(delegator), amount);
        assertEq(stakeManager.slashableStake(delegator), amount);
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), 0);
    }

    function test_stakeFor() public {
        uint96 amount = 1000;
        address sender = makeAddr('sender');

        // Setup
        stakeToken.mint(sender, amount);
        vm.prank(sender);
        stakeToken.approve(address(stakeManager), amount);

        // Execute
        vm.prank(sender);
        stakeManager.stakeFor(delegator, amount);

        // Verify
        assertEq(stakeManager.delegatorStake(delegator), amount);
        assertEq(stakeManager.slashableStake(delegator), amount);
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), 0);
    }

    function test_unstake() public {
        uint96 amount = 1000;

        // Setup
        stakeToken.mint(delegator, amount);
        vm.startPrank(delegator);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stake(amount);

        // Execute
        uint256 withdrawalId = stakeManager.unstake(500);
        vm.stopPrank();

        // Verify
        assertEq(withdrawalId, 0);
        assertEq(stakeManager.delegatorStake(delegator), 500);
        assertEq(stakeManager.slashableStake(delegator), 1000);
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), 500);

        IStakeManager.PendingWithdrawal memory withdrawal = stakeManager.withdrawal(delegator, withdrawalId);
        assertEq(withdrawal.amount, 500);
        assertEq(withdrawal.timestamp, block.timestamp + WITHDRAWAL_DELAY);
        assertFalse(withdrawal.withdrawn);
    }

    function test_unstake_revert_insufficientBalance() public {
        uint96 amount = 1000;

        // Setup
        stakeToken.mint(delegator, amount);
        vm.startPrank(delegator);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stake(amount);

        // Expect revert
        vm.expectRevert(IStakeManager.InsufficientBalance.selector);
        stakeManager.unstake(amount + 1);
        vm.stopPrank();
    }

    function test_withdraw() public {
        uint96 amount = 1000;

        // Setup
        stakeToken.mint(delegator, amount);
        vm.startPrank(delegator);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stake(amount);

        // Can't withdraw because no pending withdrawals
        vm.expectRevert(abi.encodeWithSelector(IStakeManager.NoPendingWithdrawalsToWithdraw.selector, uint64(0)));
        stakeManager.withdraw(delegator, 1);

        vm.expectEmit(true, true, true, true);
        emit IStakeManager.WithdrawalQueued(delegator, 0, 300, uint40(block.timestamp + WITHDRAWAL_DELAY));
        stakeManager.unstake(300);
        vm.expectEmit(true, true, true, true);
        emit IStakeManager.WithdrawalQueued(delegator, 1, 200, uint40(block.timestamp + WITHDRAWAL_DELAY));
        stakeManager.unstake(200);

        // Can't withdraw yet (before delay)
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakeManager.NoPendingWithdrawalsToWithdraw.selector, uint64(block.timestamp + WITHDRAWAL_DELAY)
            )
        );
        stakeManager.withdraw(delegator, 2);

        // Advance time past the delay
        vm.warp(block.timestamp + WITHDRAWAL_DELAY + 1);

        // Now we can withdraw
        uint96 withdrawnAmount = stakeManager.withdraw(delegator, 2);
        vm.stopPrank();

        // Verify
        assertEq(withdrawnAmount, 500);
        assertEq(stakeManager.delegatorStake(delegator), 500);
        assertEq(stakeManager.slashableStake(delegator), 500);
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), 0);
        assertEq(stakeToken.balanceOf(delegator), 500);
    }

    function test_withdraw_partial() public {
        uint96 amount = 1000;

        // Setup
        stakeToken.mint(delegator, amount);
        vm.startPrank(delegator);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stake(amount);

        stakeManager.unstake(300);
        stakeManager.unstake(200);
        stakeManager.unstake(100);

        // Advance time past the delay
        vm.warp(block.timestamp + WITHDRAWAL_DELAY + 1);

        // Only withdraw the first 2 pending withdrawals
        uint96 withdrawnAmount = stakeManager.withdraw(delegator, 2);
        vm.stopPrank();

        // Verify
        assertEq(withdrawnAmount, 500);
        assertEq(stakeManager.delegatorStake(delegator), 400);
        assertEq(stakeManager.slashableStake(delegator), 500);
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), 100);
        assertEq(stakeToken.balanceOf(delegator), 500);
    }

    function test_slashDelegatorStake() public {
        uint96 amount = 1000;

        // Setup
        stakeToken.mint(delegator, amount);
        vm.startPrank(delegator);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stake(amount);
        stakeManager.unstake(400);
        vm.stopPrank();

        // Use the exposed slashDelegatorStake function (80% remaining)
        uint256 remainingPercentage = 0.8e18; // 80% in fixed point
        stakeManager.slashDelegatorStake(delegator, remainingPercentage);

        // Verify - after slashing 20%, we should have 80% of the original stake left
        assertEq(stakeManager.delegatorStake(delegator), 480); // 600 * 0.8 = 480
        assertEq(stakeManager.slashableStake(delegator), 800); // 1000 * 0.8 = 800
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), 320); // 400 * 0.8 = 320

        // Check the slashing beneficiary received the slashed tokens
        assertEq(stakeToken.balanceOf(slashingBeneficiary), 200); // 1000 * 0.2 = 200
    }

    function test_slashDelegatorStake_multiplePendingWithdrawals() public {
        uint96 amount = 1000;

        // Setup
        stakeToken.mint(delegator, amount);
        vm.startPrank(delegator);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stake(amount);
        // Create two pending withdrawals
        stakeManager.unstake(200);
        stakeManager.unstake(300);
        vm.stopPrank();

        // Use the exposed slashDelegatorStake function (70% remaining)
        uint256 remainingPercentage = 0.7e18; // 70% in fixed point
        vm.expectEmit();
        emit IStakeManager.PendingWithdrawalsInvalidated(delegator, 0, 1);
        stakeManager.slashDelegatorStake(delegator, remainingPercentage);

        // Verify - after slashing 30%, we should have 70% of the original stake left
        assertEq(stakeManager.delegatorStake(delegator), 350); // 500 * 0.7 = 350
        assertEq(stakeManager.slashableStake(delegator), 700); // 1000 * 0.7 = 700
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), 350); // 500 * 0.7 = 350

        // Check the slashing beneficiary received the slashed tokens
        assertEq(stakeToken.balanceOf(slashingBeneficiary), 300); // 1000 * 0.3 = 300

        // Check that only one pending withdrawal remains after slashing
        IStakeManager.PendingWithdrawal memory pendingWithdrawal = stakeManager.withdrawal(delegator, 2);
        assertEq(pendingWithdrawal.amount, 350);
        assertEq(pendingWithdrawal.timestamp, block.timestamp + WITHDRAWAL_DELAY);
        assertFalse(pendingWithdrawal.withdrawn);
    }
}
