// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/// @title IService
/// @notice This interface is used by contracts that operators deposit their ERC-721 tokens into to operate for. It must implement the following functions in order to be notified of changes to operator's and delegator's stake.
interface IService is IERC165 {
    /// @notice This function is called when a delegator's stake changes.
    /// @param operator The address of the operator.
    /// @param newBalance The new balance of the operator.
    /// @param delegator The address of the delegator.
    /// @param newDelegatorStake The new stake of the delegator.
    function reportOperatorStake(address operator, uint96 newBalance, address delegator, uint96 newDelegatorStake)
        external;

    /// @notice This function is called when an operator is slashed.
    /// @param operator The address of the operator.
    /// @param remainingPercentage The remaining percentage of the operator's stake.
    function reportOperatorSlash(address operator, uint256 remainingPercentage) external;

    /// @notice This function is called when an operator ERC-721 token is forcefully withdrawn.
    /// @param operator The address of the operator.
    function onForceWithdrawal(address operator) external;
}
