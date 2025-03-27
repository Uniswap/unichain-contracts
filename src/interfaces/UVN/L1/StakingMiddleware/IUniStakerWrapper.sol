// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IUniStaker} from '../IUnistaker.sol';
import {IStakeManager} from './IStakeManager.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title UniStakerWrapper - Base contract for the StakingMiddleware
/// @notice This contract manages deposits into the UniStaker contract. It allows delegators to participate in UNI governance and accrue protocol fees distributed by the UniStaker contract. The deposit into UniStaker is optional, once a delegator opts in, all subsequent deposits will also be deposited into the UniStaker contract.
interface IUniStakerWrapper is IStakeManager {
    /// @notice Thrown when a user attempts to deposit into the UniStaker contract while already deposited
    error AlreadyDepositedIntoUniStaker();
    /// @notice Thrown when a user attempts to withdraw from the UniStaker contract while not deposited
    error NotDepositedIntoUniStaker();

    /// @notice Thrown when a user attempts to deposit into the UniStaker contract while not staking any amount
    error NoStakeToDeposit();

    /// @notice Emitted when a user deposits into the UniStaker contract
    event UniStakerDeposited(address indexed delegator, uint256 indexed depositId, uint96 amount);

    /// @notice Emitted when a user withdraws from the UniStaker contract
    event UniStakerWithdrawn(address indexed delegator, uint256 indexed depositId, uint96 amount);

    /// @notice Emitted when a user alters the governance delegatee of their underlying stake in the UniStaker contract
    event GovernanceDelegateeAltered(address indexed delegator, address newGovernanceDelegatee);

    /// @notice Deposits the user's underlying stake into the UniStaker contract
    /// @param governanceDelegatee The address of the governance delegatee to set
    /// @return depositId The depositId of the deposit identifying the deposit in the UniStaker contract
    /// @dev Any subsequent deposits will also be deposited into the UniStaker contract
    function depositIntoUniStaker(address governanceDelegatee) external returns (uint256 depositId);

    /// @notice Withdraws all of the user's underlying stake from the UniStaker contract
    function withdrawFromUniStaker() external;

    /// @notice Alters the governance delegatee of the user's underlying stake in the UniStaker contract
    function alterGovernanceDelegatee(address newGovernanceDelegatee) external;

    /// @notice Returns whether the user has deposited their underlying stake into the UniStaker contract
    /// @param delegator The address of the delegator
    /// @return Whether the user has deposited into the UniStaker contract
    function isDepositedIntoUniStaker(address delegator) external view returns (bool);

    /// @notice Returns the UniStaker contract
    function UNISTAKER() external view returns (IUniStaker);

    /// @notice Returns the reward token
    function REWARD_TOKEN() external view returns (IERC20);
}
