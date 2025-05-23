// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC7751} from '../../IERC7751.sol';
import {IBaseService} from '../IBaseService.sol';
import {IDelegatorClaim} from './IDelegatorClaim.sol';
import {IStakeTable} from './IStakeTable.sol';

/// @title IL2StakeTable - Interface for the L2 stake table contract
/// @notice This contract is a clone of the L1 stake table. Whenever the balance of an operator changes on L1, this contract is notified and the balance is updated on L2. This contract deploys a default contract for delegators to claim rewards when the ERC-721 token is deposited on L1. This contract is then notified of subsequent stake changes on L1. Operators can override the default delegator claim contract with a custom implementation to distribute rewards differently.
interface IL2StakeTable is IBaseService, IStakeTable, IERC7751 {
    /// @notice Emitted when an operator sets a delegator claim contract
    event DelegatorClaimContractSet(address indexed operator, IDelegatorClaim delegatorClaim);
    /// @notice Emitted when a delegator stake update fails
    event DelegatorStakeUpdateFailed(address indexed operator, address delegator, bytes reason);

    /// @notice Thrown when the caller is not the L1 stake table sync contract
    error NotStakeTableSync();
    /// @notice Thrown when a delegation is attempted
    error DelegationDisabled();
    /// @notice Thrown when the caller is not the L2 stake table contract
    error OnlyCallableBySelf();
    /// @notice Thrown when the delegator claim contract is set to a zero address
    error ZeroAddress();
    /// @notice Thrown when the delegator claim contract has no code
    error NoCode();

    /// @notice Sets a delegator claim contract for an operator
    /// @param delegatorClaim The delegator claim contract to set
    /// @dev Allows an operator to override the default delegator claim contract with a custom implementation
    function overrideDelegatorClaimContract(IDelegatorClaim delegatorClaim) external;
}
