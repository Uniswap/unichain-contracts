// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddlewareParams} from './IStakingMiddlewareParams.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStakeManager is IStakingMiddlewareParams {
    struct PendingWithdrawal {
        uint96 amount;
        uint40 timestamp;
        bool withdrawn;
    }

    /// @notice Emitted when a delegator deposits a stake in the StakingMiddleware contract
    event Staked(address indexed delegator, address indexed sender, uint96 amount);

    /// @notice Emitted when a delegator unstakes a stake from the StakingMiddleware contract
    event Unstaked(address indexed delegator, uint96 amount, uint40 unlocksAt);

    /// @notice Emitted when a delegator withdraws unstaked stakes from the StakingMiddleware contract
    event Withdrawn(address indexed delegator, address indexed recipient, uint96 amount);

    /// @notice Emitted when a delegator's pending withdrawals are invalidated during slashing
    event PendingWithdrawalsInvalidated(
        address indexed delegator, uint256 start, uint256 end, uint96 newWithdrawalAmount, uint40 newWithdrawalTimestamp
    );

    /// @notice Emitted when a delegator's stake is slashed
    event Slashed(address indexed delegator, uint96 amount, uint96 newStake);

    /// @notice Thrown when a user attempts to withdraw more stake than they have deposited
    error InsufficientBalance();

    /// @notice Thrown when a user attempts to withdraw stakes that are not yet unlocked
    /// @dev `nextWithdrawableTimestamp` will be 0 if there are no pending withdrawals
    error NoPendingWithdrawalsToWithdraw(uint64 nextWithdrawableTimestamp);

    /// @notice Deposits a stake in the StakingMiddleware contract
    function stake(uint96 amount) external;

    /// @notice Deposits a stake in the StakingMiddleware contract on behalf of a delegator
    function stakeFor(address delegator, uint96 amount) external;

    /// @notice Unstakes a stake from the StakingMiddleware contract and queues it for withdrawal
    /// @dev All pending withdrawals are still slashable if delegated to an operator even if the withdrawals are already unlocked!
    function unstake(uint96 amount) external returns (uint256 withdrawalId);

    /// @notice Withdraws unstaked stakes that are pending to be withdrawn from the StakingMiddleware contract
    /// @param to The address to send the unstaked stakes to
    /// @param n The number of pending withdrawals to complete
    /// @return The total amount of unstaked stakes withdrawn
    /// @dev If `n` is greater than the number of unlocked pending withdrawals, the function will return early.
    function withdraw(address to, uint64 n) external returns (uint96);

    /// @notice Returns the stake of a delegator deposited in the StakingMiddleware contract
    function delegatorStake(address delegator) external view returns (uint96);

    /// @notice Returns the slashable stake of a delegator
    /// @dev The slashable stake is the `delegatorStake` + the total pending withdrawals
    function slashableStake(address delegator) external view returns (uint96);

    /// @notice Returns the amount of pending withdrawals for a delegator
    function pendingWithdrawalAmount(address delegator) external view returns (uint96);

    /// @notice Returns a withdrawal for a delegator
    function withdrawal(address delegator, uint256 withdrawalId)
        external
        view
        returns (IStakeManager.PendingWithdrawal memory);

    /// @notice Returns the stake token
    function STAKE_TOKEN() external view returns (IERC20);
}
