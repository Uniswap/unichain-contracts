// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddlewareParams} from './IStakingMiddlewareParams.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStakeManager is IStakingMiddlewareParams {
    /// @notice Emitted when a delegator deposits a stake in the StakingMiddleware contract
    event StakeDeposited(address indexed delegator, uint96 amount);

    /// @notice Emitted when a delegator withdraws a stake from the StakingMiddleware contract
    event StakeWithdrawn(address indexed delegator, uint96 amount);

    /// @notice Emitted when a delegator's stake is slashed
    event StakeSlashed(address indexed delegator, uint96 amount);

    /// @notice Thrown when a user attempts to withdraw more stake than they have deposited
    error InsufficientBalance();

    /// @notice Returns the stake of a delegator deposited in the StakingMiddleware contract
    function delegatorStake(address delegator) external view returns (uint96);

    /// @notice Deposits a stake in the StakingMiddleware contract
    function deposit(uint96 amount) external;

    /// @notice Withdraws a stake from the StakingMiddleware contract
    function withdraw(uint96 amount) external;

    /// @notice Returns the stake token
    function STAKE_TOKEN() external view returns (IERC20);
}
