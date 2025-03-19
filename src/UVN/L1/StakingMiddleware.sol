// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddleware} from '../../interfaces/UVN/L1/IStakingMiddleware.sol';
import {IUniStaker} from '../../interfaces/UVN/L1/IUnistaker.sol';
import {SlashingManager} from './StakingMiddleware/SlashingManager.sol';
import {UniStakerWrapper} from './StakingMiddleware/UniStakerWrapper.sol';
import {Multicall} from '@openzeppelin/contracts/utils/Multicall.sol';
import {Nonces} from '@openzeppelin/contracts/utils/Nonces.sol';

/// @title StakingMiddleware
/// @notice This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.
contract StakingMiddleware is SlashingManager, Multicall, IStakingMiddleware {
    constructor(IUniStaker unistaker_, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {}

    /// @inheritdoc Nonces
    /// @dev The `Nonces` library does not come with an interface, to ensure that the function is included in the interface of this contract, add it here
    function nonces(address owner) public view override(Nonces, IStakingMiddleware) returns (uint256) {
        return super.nonces(owner);
    }
}
