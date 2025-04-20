// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC7751} from '../../../interfaces/IERC7751.sol';
import {IDelegatorClaim} from './IDelegatorClaim.sol';
import {IOperatorFeeManager} from './IOperatorFeeManager.sol';

/// @title DefaultDelegatorClaim - A default implementation of IDelegatorClaim
/// @notice This contract distributes rewards sent to it by the reward distributor contract. Additionally the contract allows an operator to define arbitrary logic on how to handle their fees.
interface IDefaultDelegatorClaim is IDelegatorClaim, IERC7751 {
    /// @notice Emitted when the balance of a delegator changes
    event BalanceUpdated(address indexed delegator, uint256 newBalance);
    /// @notice Emitted when rewards are distributed to delegators and the operator fee is taken
    event RewardDistributed(uint256 delegatorReward, uint256 operatorFee);
    /// @notice Emitted when the operator fee manager is set
    event OperatorFeeManagerSet(address newOperatorFeeManager);
    /// @notice Emitted when rewards are claimed by a delegator
    event RewardsClaimed(address indexed delegator, address indexed to, uint256 amount);

    /// @notice Thrown when the caller is not the stake table
    error NotStakeTable();
    /// @notice Thrown when the ETH transfer fails
    error EthTransferFailed();
    /// @notice Thrown when there are no delegations when distributing rewards
    error NoDelegations();
    /// @notice Thrown when the operator fee exceeds the reward
    error OperatorFeeExceedsReward();
    /// @notice Thrown when the caller is not the operator
    error NotOperator();
    /// @notice Thrown when the caller is not the delegator or an aliased address of the delegator from L1
    error NotDelegator();

    /// @notice Sets the operator fee manager
    /// @param operatorFeeManager The address of the operator fee manager
    /// @dev Only the operator can set the operator fee manager
    function setOperatorFeeManager(IOperatorFeeManager operatorFeeManager) external;

    /// @notice Allows a delegator to claim their rewards
    /// @param delegator The address of the delegator
    /// @param to The address to send the rewards to
    /// @dev The caller must be the delegator or an aliased address of the delegator from L1
    /// @dev When implementing a contract on L1 that acts as a delegator make sure that a contract that can call this function cannot be deployed on L2 by a 3rd party as this would allow them to claim rewards for the delegator.
    function claimRewards(address delegator, address to) external;

    /// @notice Returns the rewards of a delegator
    /// @param account The address of the delegator
    /// @return The rewards of the delegator
    function rewardsOf(address account) external view returns (uint256);

    /// @notice Returns the operator fee manager
    /// @return The operator fee manager
    function operatorFeeManager() external view returns (IOperatorFeeManager);

    /// @notice Returns the total amount delegated to an operator
    /// @return The total delegated amount
    function totalDelegation() external view returns (uint256);

    /// @notice Returns the amount delegated to an operator by a delegator
    /// @param delegator The address of the delegator
    /// @return The delegation of the delegator
    function delegationOf(address delegator) external view returns (uint256);

    /// @notice Returns the operator
    /// @return The operator
    function OPERATOR() external view returns (address);
}
