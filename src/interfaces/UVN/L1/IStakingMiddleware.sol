// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {INotifier} from './StakingMiddleware/INotifier.sol';

/// @title StakingMiddleware
/// @notice This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.
interface IStakingMiddleware is INotifier {
    /// @notice Returns the nonces used for delegation by signature
    function nonces(address owner) external view returns (uint256);
}
