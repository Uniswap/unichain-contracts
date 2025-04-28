// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakeManager} from '../../../../src/UVN/L1/StakingMiddleware/StakeManager.sol';
import {IStakeManager} from '../../../../src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol';

import {MockVotesToken} from '../../../mock/MockVotesToken.sol';
import {L1TestHandler} from '../L1TestHandler.sol';
import {Test} from 'forge-std/Test.sol';

/// @notice Wrapper around StakeManager to test it in isolation
contract StakeManagerTestHarness is StakeManager {
    struct Stake_ {
        uint96 stake;
        uint96 totalPendingWithdrawal;
        uint64 head;
        IStakeManager.PendingWithdrawal[] pendingWithdrawals;
    }

    mapping(address delegator => Stake_) private _ghostDepositorStake;

    constructor(address stakeToken, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        StakeManager(stakeToken, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {}

    /// @notice Helper function to test the internal _slashDelegatorStake function
    function slashDelegatorStake(address delegator, uint256 remainingPercentage) external {
        _slashDelegatorStake(delegator, remainingPercentage);
    }

    /// Implement _before* hooks to track changes to the ghost stake

    function _beforeStake(address delegator, uint96 amount) internal override {
        super._beforeStake(delegator, amount);
        _ghostDepositorStake[delegator].stake += amount;
    }

    function _beforeUnstake(address delegator, uint96 amount) internal override {
        super._beforeUnstake(delegator, amount);
        _ghostDepositorStake[delegator].stake -= amount;
        // Add pending withdraw to ghost stake
        _ghostSchedulePendingWithdrawal(delegator, amount);
    }

    function _beforeDelegatorSlashed(
        address delegator,
        uint96 amount,
        uint96 newStake,
        uint96 newPendingWithdrawalAmount
    ) internal override {
        super._beforeDelegatorSlashed(delegator, amount, newStake, newPendingWithdrawalAmount);

        Stake_ storage stake_ = _ghostDepositorStake[delegator];
        uint256 currentPendingWithdrawalAmount = stake_.totalPendingWithdrawal;
        // set equal to new stake
        _ghostDepositorStake[delegator].stake = newStake;

        if (currentPendingWithdrawalAmount != 0) {
            // cancel all pending withdrawals and schedule a new one with the remainder
            _ghostInvalidatePendingWithdrawals(delegator);
            _ghostSchedulePendingWithdrawal(delegator, newPendingWithdrawalAmount);
        }
    }

    function getStake(address delegator) external view returns (Stake_ memory) {
        return _ghostDepositorStake[delegator];
    }

    /// Ghost mirrored functions from StakeManager

    function _ghostInvalidatePendingWithdrawals(address delegator) private {
        Stake_ storage stake_ = _ghostDepositorStake[delegator];
        uint64 currentHead = stake_.head;
        uint64 currentLength = uint64(stake_.pendingWithdrawals.length);
        stake_.head = currentLength;
        stake_.totalPendingWithdrawal = 0;
        emit PendingWithdrawalsInvalidated(delegator, currentHead, currentLength - 1);
    }

    function _ghostSchedulePendingWithdrawal(address delegator, uint96 amount) private returns (uint256 withdrawalId) {
        Stake_ storage stake_ = _ghostDepositorStake[delegator];
        uint40 scheduledAt = uint40(block.timestamp);
        withdrawalId = stake_.pendingWithdrawals.length;
        stake_.totalPendingWithdrawal += amount;
        stake_.pendingWithdrawals.push(
            IStakeManager.PendingWithdrawal({amount: amount, scheduledAt: scheduledAt, withdrawn: false})
        );
        emit WithdrawalQueued(delegator, withdrawalId, amount, scheduledAt + uint40(withdrawalDelay()));
    }
}

contract StakeManagerInvariantHandler is Test {
    StakeManagerTestHarness stakeManagerTestHarness;
    MockVotesToken stakeToken;

    address[] public actors;
    address internal currentActor;

    constructor(address _stakeManagerTestHarness, address _stakeToken, address[] memory _actors) {
        stakeManagerTestHarness = StakeManagerTestHarness(_stakeManagerTestHarness);
        stakeToken = MockVotesToken(_stakeToken);
        actors = _actors;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    function _boundUpperUint96(uint96 amount, uint96 _stake) internal pure returns (uint96) {
        return uint96(bound(amount, 0, type(uint96).max - _stake));
    }

    function _boundToUint96(uint96 amount, uint96 _max) internal pure returns (uint96) {
        return uint96(bound(amount, 0, _max));
    }

    function _boundToUint256(uint256 amount, uint256 _max) internal pure returns (uint256) {
        return uint256(bound(amount, 0, _max));
    }

    function stake(uint96 amount, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        uint96 _delegatorStake = stakeManagerTestHarness.delegatorStake(currentActor);
        uint96 _slashableStake = stakeManagerTestHarness.slashableStake(currentActor);

        amount = _boundUpperUint96(amount, _slashableStake);

        stakeToken.mint(currentActor, amount);
        vm.startPrank(currentActor);
        stakeToken.approve(address(stakeManagerTestHarness), amount);
        stakeManagerTestHarness.stake(amount);
        vm.stopPrank();

        assertEq(stakeManagerTestHarness.delegatorStake(currentActor), _delegatorStake + amount);
        assertEq(stakeManagerTestHarness.slashableStake(currentActor), _slashableStake + amount);
    }

    /// @dev Amount is minted to this contract and staked for the actor
    function stakeFor(uint96 amount) external {
        uint96 _delegatorStake = stakeManagerTestHarness.delegatorStake(currentActor);
        uint96 _slashableStake = stakeManagerTestHarness.slashableStake(currentActor);

        amount = _boundUpperUint96(amount, _slashableStake);

        stakeToken.mint(address(this), amount);
        stakeToken.approve(address(stakeManagerTestHarness), amount);
        stakeManagerTestHarness.stakeFor(currentActor, amount);

        assertEq(stakeManagerTestHarness.delegatorStake(currentActor), _delegatorStake + amount);
        assertEq(stakeManagerTestHarness.slashableStake(currentActor), _slashableStake + amount);
    }

    function unstake(uint96 amount, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        uint96 _delegatorStake = stakeManagerTestHarness.delegatorStake(currentActor);
        uint96 _slashableStake = stakeManagerTestHarness.slashableStake(currentActor);

        // Bound the amount to the current delegator stake
        amount = _boundToUint96(amount, _delegatorStake);

        stakeManagerTestHarness.unstake(amount);

        assertEq(stakeManagerTestHarness.delegatorStake(currentActor), _delegatorStake - amount);
        // No change to slashable stake because it includes pending withdrawals
        assertEq(stakeManagerTestHarness.slashableStake(currentActor), _slashableStake);
    }

    function withdraw(uint64 n, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        StakeManagerTestHarness.Stake_ memory _ghostDepositorStake = stakeManagerTestHarness.getStake(currentActor);
        uint256 len = _ghostDepositorStake.pendingWithdrawals.length;
        uint64 head = _ghostDepositorStake.head;

        // Use try/catch to have more flexibility with handling conditional reverts
        uint96 amount;
        try stakeManagerTestHarness.withdraw(currentActor, n) returns (uint96 _amount) {
            amount = _amount;
        } catch (bytes memory revertData) {
            // If there are no pending withdrawals, expect the revert with 0
            if (head == len) {
                assertEq(revertData, abi.encodeWithSelector(IStakeManager.NoPendingWithdrawalsToWithdraw.selector, 0));
            }
            // If there are pending withdraws expect the revert with the nextTimestamp
            else if (len > 0) {
                IStakeManager.PendingWithdrawal memory pendingWithdrawal = _ghostDepositorStake.pendingWithdrawals[head];
                uint40 nextTimestamp = pendingWithdrawal.scheduledAt;
                assertEq(
                    revertData,
                    abi.encodeWithSelector(
                        IStakeManager.NoPendingWithdrawalsToWithdraw.selector,
                        nextTimestamp + stakeManagerTestHarness.withdrawalDelay()
                    )
                );
            }
        }

        _ghostDepositorStake.head = head;
        _ghostDepositorStake.totalPendingWithdrawal -= amount;
    }

    function slash(uint256 remainingPercentage, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        uint96 _delegatorStake = stakeManagerTestHarness.delegatorStake(currentActor);
        uint96 _slashableStake = stakeManagerTestHarness.slashableStake(currentActor);

        remainingPercentage = _boundToUint256(remainingPercentage, 1e18);

        stakeManagerTestHarness.slashDelegatorStake(currentActor, remainingPercentage);

        // Stakes after slashing must be less than or equal to the original stake
        assertLe(stakeManagerTestHarness.delegatorStake(currentActor), _delegatorStake);
        assertLe(stakeManagerTestHarness.slashableStake(currentActor), _slashableStake);
    }
}

contract StakeManagerTest is L1TestHandler {
    StakeManagerTestHarness stakeManager;
    uint256 constant WITHDRAWAL_DELAY = 7 days;

    address initialAdmin = makeAddr('initial admin');

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

    /// @notice Fuzz test for the stake function
    function test_stake_fuzz(uint96 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < type(uint96).max);

        stakeToken.mint(delegator, amount);
        vm.startPrank(delegator);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stake(amount);
        vm.stopPrank();

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

    /// @notice Fuzz test for the stakeFor function
    function test_stakeFor_fuzz(uint96 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < type(uint96).max);

        address sender = makeAddr('sender');

        stakeToken.mint(sender, amount);
        vm.startPrank(sender);
        stakeToken.approve(address(stakeManager), amount);
        stakeManager.stakeFor(delegator, amount);
        vm.stopPrank();

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
        uint256 withdrawalId = stakeManager.unstake(amount);
        vm.stopPrank();

        // Verify
        assertEq(withdrawalId, 0);
        assertEq(stakeManager.delegatorStake(delegator), 0);
        assertEq(stakeManager.slashableStake(delegator), amount);
        assertEq(stakeManager.pendingWithdrawalAmount(delegator), amount);

        IStakeManager.PendingWithdrawal memory withdrawal = stakeManager.withdrawal(delegator, withdrawalId);
        assertEq(withdrawal.amount, amount);
        assertEq(withdrawal.scheduledAt, block.timestamp);
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
        assertEq(pendingWithdrawal.scheduledAt, block.timestamp);
        assertFalse(pendingWithdrawal.withdrawn);
    }
}

contract StakeManagerInvariantTest is L1TestHandler {
    StakeManagerInvariantHandler invariantHandler;
    StakeManagerTestHarness stakeManager;
    uint256 constant WITHDRAWAL_DELAY = 7 days;

    address initialAdmin = makeAddr('initial admin');
    address sender = makeAddr('sender');

    function setUp() public override {
        super.setUp();
        address[] memory actors = new address[](1);
        actors[0] = delegator;

        stakeManager =
            new StakeManagerTestHarness(address(stakeToken), initialAdmin, WITHDRAWAL_DELAY, slashingBeneficiary);
        invariantHandler = new StakeManagerInvariantHandler(address(stakeManager), address(stakeToken), actors);

        targetContract(address(invariantHandler));
        targetSender(sender);
    }

    function invariant_delegatorStakeMustBeLessThanOrEqualToSlashableStake() public view {
        assert(stakeManager.delegatorStake(delegator) <= stakeManager.slashableStake(delegator));
    }
}
