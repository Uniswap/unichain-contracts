// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20, IStakeManager} from '../../../interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol';
import {StakingMiddlewareParams} from './StakingMiddlewareParams.sol';

/// @title StakeManager - Base contract for the StakingMiddleware
/// @notice This contract is used to manage the stake of a delegator. Delegators can stake the UNI token and withdraw their stake after a delay. After a delegator unstakes, their stake remains slashable until the withdrawal is completed (even if the withdrawal delay has passed but the stake has not been withdrawn yet). Slashings are always applied percentually to the entire stake, including pending withdrawals.
contract StakeManager is StakingMiddlewareParams, IStakeManager {
    uint256 internal constant PERCENTAGE_DENOMINATOR = 1e18;

    struct Stake {
        uint96 stake;
        uint96 totalPendingWithdrawal;
        uint64 head;
        IStakeManager.PendingWithdrawal[] pendingWithdrawals;
    }

    mapping(address delegator => Stake stake) private _depositorStake;

    IERC20 public immutable STAKE_TOKEN;

    constructor(address stakeToken, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        StakingMiddlewareParams(initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {
        STAKE_TOKEN = IERC20(stakeToken);
    }

    /// @inheritdoc IStakeManager
    function stake(uint96 amount) external {
        stakeFor(msg.sender, amount);
    }

    /// @inheritdoc IStakeManager
    function stakeFor(address delegator, uint96 amount) public {
        _beforeStake(delegator, amount);
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        STAKE_TOKEN.transferFrom(msg.sender, address(this), amount);
        _depositorStake[delegator].stake += amount;
        emit Staked(delegator, msg.sender, amount);
        _afterStake(delegator, amount);
    }

    /// @inheritdoc IStakeManager
    function unstake(uint96 amount) external returns (uint256 withdrawalId) {
        _beforeUnstake(msg.sender, amount);
        Stake storage stake_ = _depositorStake[msg.sender];
        uint256 currentStake = stake_.stake;
        if (currentStake < amount) revert InsufficientBalance();
        stake_.stake -= amount;
        withdrawalId = _schedulePendingWithdrawal(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
        _afterUnstake(msg.sender, amount);
    }

    /// @inheritdoc IStakeManager
    function withdraw(address to, uint64 n) external returns (uint96 amount) {
        Stake storage stake_ = _depositorStake[msg.sender];
        uint256 len = stake_.pendingWithdrawals.length;
        uint64 head = stake_.head;
        if (head == len) revert NoPendingWithdrawalsToWithdraw(0);
        uint256 i = 0;
        for (; head < len; head++) {
            if (i == n) break;
            IStakeManager.PendingWithdrawal storage pendingWithdrawal = stake_.pendingWithdrawals[head];
            uint40 nextTimestamp = pendingWithdrawal.timestamp;
            if (nextTimestamp > block.timestamp) {
                if (i == 0) revert NoPendingWithdrawalsToWithdraw(nextTimestamp);
                break;
            }
            amount += pendingWithdrawal.amount;
            pendingWithdrawal.withdrawn = true;
            i++;
        }
        stake_.head = head;
        stake_.totalPendingWithdrawal -= amount;
        _beforeWithdraw(msg.sender, amount);
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        STAKE_TOKEN.transfer(to, amount);
        emit Withdrawn(msg.sender, to, amount);
        _afterWithdraw(msg.sender, amount);
    }

    /// @inheritdoc IStakeManager
    function delegatorStake(address delegator) public view virtual returns (uint96) {
        return _delegatorStake(delegator);
    }

    /// @inheritdoc IStakeManager
    function slashableStake(address delegator) public view virtual returns (uint96) {
        return _slashableStake(delegator);
    }

    /// @inheritdoc IStakeManager
    function pendingWithdrawalAmount(address delegator) external view returns (uint96) {
        return _depositorStake[delegator].totalPendingWithdrawal;
    }

    /// @inheritdoc IStakeManager
    function withdrawal(address delegator, uint256 withdrawalId)
        external
        view
        returns (IStakeManager.PendingWithdrawal memory)
    {
        return _depositorStake[delegator].pendingWithdrawals[withdrawalId];
    }

    /// @dev To ensure accurate accounting of total delegated stake to operators, pending withdrawals and slashable stake are slashed equally
    /// @dev When pending withdrawals are slashed, cancel all pending withdrawals and create a new one with the remainder
    // @audit INVARIANT: The remaining slashed stake is always less or equal to the stake before the slashing minus the amount slashed to ensure the contract always has enough stake to cover the withdrawal of the entire stake
    function _slashDelegatorStake(address delegator, uint256 remainingPercentage) internal {
        Stake storage stake_ = _depositorStake[delegator];
        uint256 currentStake = stake_.stake;
        uint256 currentPendingWithdrawalAmount = stake_.totalPendingWithdrawal;
        uint96 newStake = uint96(currentStake * remainingPercentage / PERCENTAGE_DENOMINATOR);
        uint96 newPendingWithdrawalAmount =
            uint96(currentPendingWithdrawalAmount * remainingPercentage / PERCENTAGE_DENOMINATOR);
        if (currentPendingWithdrawalAmount != 0) {
            // cancel all pending withdrawals and schedule a new one with the remainder
            _invalidatePendingWithdrawals(delegator);
            _schedulePendingWithdrawal(delegator, newPendingWithdrawalAmount);
        }
        if (currentStake != 0) {
            _depositorStake[delegator].stake = uint96(newStake);
        }
        uint96 slashedAmount =
            uint96(currentStake + currentPendingWithdrawalAmount - newStake - newPendingWithdrawalAmount);
        _beforeDelegatorSlashed(delegator, slashedAmount, newStake, newPendingWithdrawalAmount);
        STAKE_TOKEN.transfer(slashingBeneficiary(), slashedAmount);
        emit Slashed(delegator, slashedAmount, newStake);
        _afterDelegatorSlashed(delegator, slashedAmount, newStake, newPendingWithdrawalAmount);
    }

    function _schedulePendingWithdrawal(address delegator, uint96 amount)
        internal
        virtual
        returns (uint256 withdrawalId)
    {
        Stake storage stake_ = _depositorStake[delegator];
        uint40 unlocksAt = uint40(block.timestamp + withdrawalDelay());
        withdrawalId = stake_.pendingWithdrawals.length;
        stake_.totalPendingWithdrawal += amount;
        stake_.pendingWithdrawals.push(
            IStakeManager.PendingWithdrawal({amount: amount, timestamp: unlocksAt, withdrawn: false})
        );
        emit WithdrawalQueued(delegator, withdrawalId, amount, unlocksAt);
    }

    function _invalidatePendingWithdrawals(address delegator) private {
        Stake storage stake_ = _depositorStake[delegator];
        uint64 currentHead = stake_.head;
        uint64 currentLength = uint64(stake_.pendingWithdrawals.length);
        stake_.head = currentLength;
        stake_.totalPendingWithdrawal = 0;
        emit PendingWithdrawalsInvalidated(delegator, currentHead, currentLength - 1);
    }

    // @audit this function should only be called if all slashing instances for a delegator have been applied
    function _delegatorStake(address delegator) internal view virtual returns (uint96) {
        return _depositorStake[delegator].stake;
    }

    /// @dev slashable stake is the sum of the stake and the total pending withdrawals
    // @audit this function should only be called if all slashing instances for a delegator have been applied
    function _slashableStake(address delegator) internal view virtual returns (uint96) {
        return _depositorStake[delegator].stake + _depositorStake[delegator].totalPendingWithdrawal;
    }

    function _beforeStake(address delegator, uint96 amount) internal virtual {}

    function _afterStake(address delegator, uint96 amount) internal virtual {}

    function _beforeUnstake(address delegator, uint96 amount) internal virtual {}

    function _afterUnstake(address delegator, uint96 amount) internal virtual {}

    function _beforeWithdraw(address delegator, uint96 amount) internal virtual {}

    function _afterWithdraw(address delegator, uint96 amount) internal virtual {}

    function _beforeDelegatorSlashed(
        address delegator,
        uint96 amount,
        uint96 newStake,
        uint96 newPendingWithdrawalAmount
    ) internal virtual {}

    function _afterDelegatorSlashed(
        address delegator,
        uint96 amount,
        uint96 newStake,
        uint96 newPendingWithdrawalAmount
    ) internal virtual {}
}
