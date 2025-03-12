// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20, IStakeManager} from '../../../interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol';
import {StakingMiddlewareParams} from './StakingMiddlewareParams.sol';

contract StakeManager is StakingMiddlewareParams, IStakeManager {
    // TODO scale to 1e27 to minimize precision loss
    uint96 internal constant PERCENTAGE_DENOMINATOR = 1e18;

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
        Stake storage stake_ = _depositorStake[msg.sender];
        uint256 currentStake = stake_.stake;
        if (currentStake < amount) revert InsufficientBalance();
        _beforeUnstake(msg.sender, amount);
        stake_.stake -= amount;
        stake_.totalPendingWithdrawal += amount;
        uint40 unlocksAt = uint40(block.timestamp + withdrawalDelay());
        withdrawalId = stake_.pendingWithdrawals.length;
        stake_.pendingWithdrawals.push(
            IStakeManager.PendingWithdrawal({amount: amount, timestamp: unlocksAt, withdrawn: false})
        );
        emit Unstaked(msg.sender, amount, unlocksAt);
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
            i++;
            IStakeManager.PendingWithdrawal storage pendingWithdrawal = stake_.pendingWithdrawals[head];
            uint40 nextTimestamp = pendingWithdrawal.timestamp;
            if (nextTimestamp > block.timestamp) {
                if (i == 0) revert NoPendingWithdrawalsToWithdraw(nextTimestamp);
                break;
            }
            amount += pendingWithdrawal.amount;
            pendingWithdrawal.withdrawn = true;
            head++;
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
    function delegatorStake(address delegator) external view returns (uint96) {
        return _delegatorStake(delegator);
    }

    /// @inheritdoc IStakeManager
    function slashableStake(address delegator) public view returns (uint96) {
        return _delegatorStake(delegator) + _depositorStake[delegator].totalPendingWithdrawal;
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

    /// @dev to ensure accurate accounting of total delegated stake to operators, pending withdrawals and slashable stake are slashed equally
    /// @dev When pending withdrawals are slashed, cancel all pending withdrawals and create a new one with the remainder
    // @audit INVARIANT: The remaining slashed stake is always less or equal to the stake before the slashing minus the amount slashed to ensure the contract always has enough stake to cover the withdrawal of the entire stake
    function _slashDelegatorStake(address delegator, uint96 amount) internal {
        Stake storage stake_ = _depositorStake[delegator];
        uint96 newStake = stake_.stake;
        uint96 newPendingWithdrawalAmount = stake_.totalPendingWithdrawal;
        uint96 totalSlashableStake = newStake + newPendingWithdrawalAmount;
        uint96 remainingPercentage = (totalSlashableStake - amount) * PERCENTAGE_DENOMINATOR / totalSlashableStake;
        if (newPendingWithdrawalAmount != 0) {
            uint64 currentHead = stake_.head;
            uint64 currentLength = uint64(stake_.pendingWithdrawals.length);
            // cancel all pending withdrawals and schedule a new one with the remainder
            stake_.head = currentLength;
            newPendingWithdrawalAmount = remainingPercentage * newPendingWithdrawalAmount / PERCENTAGE_DENOMINATOR;
            stake_.totalPendingWithdrawal = newPendingWithdrawalAmount;
            uint40 unlocksAt = uint40(block.timestamp + withdrawalDelay());
            stake_.pendingWithdrawals.push(
                IStakeManager.PendingWithdrawal({
                    amount: newPendingWithdrawalAmount,
                    timestamp: unlocksAt,
                    withdrawn: false
                })
            );
            emit PendingWithdrawalsInvalidated(
                delegator, currentHead, currentLength - 1, newPendingWithdrawalAmount, unlocksAt
            );
        }
        if (newStake != 0) {
            newStake = remainingPercentage * newStake / PERCENTAGE_DENOMINATOR;
            _depositorStake[delegator].stake = newStake;
        }
        _beforeSlash(delegator, amount, newStake, newPendingWithdrawalAmount);
        STAKE_TOKEN.transfer(slashingBeneficiary(), amount);
        emit Slashed(delegator, amount, newStake);
        _afterSlash(delegator, amount, newStake, newPendingWithdrawalAmount);
    }

    function _delegatorStake(address delegator) internal view virtual returns (uint96) {
        return _depositorStake[delegator].stake;
    }

    function _beforeStake(address delegator, uint96 amount) internal virtual {}

    function _afterStake(address delegator, uint96 amount) internal virtual {}

    function _beforeUnstake(address delegator, uint96 amount) internal virtual {}

    function _afterUnstake(address delegator, uint96 amount) internal virtual {}

    function _beforeWithdraw(address delegator, uint96 amount) internal virtual {}

    function _afterWithdraw(address delegator, uint96 amount) internal virtual {}

    function _beforeSlash(address delegator, uint96 amount, uint96 newStake, uint96 newPendingWithdrawalAmount)
        internal
        virtual
    {}

    function _afterSlash(address delegator, uint96 amount, uint96 newStake, uint96 newPendingWithdrawalAmount)
        internal
        virtual
    {}
}
