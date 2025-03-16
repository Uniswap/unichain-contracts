// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddleware} from '../../interfaces/UVN/L1/IStakingMiddleware.sol';
import {IUniStaker} from '../../interfaces/UVN/L1/IUnistaker.sol';
import {Notifier} from './StakingMiddleware/Notifier.sol';
import {UniStakerWrapper} from './StakingMiddleware/UniStakerWrapper.sol';
import {Nonces} from '@openzeppelin/contracts/utils/Nonces.sol';

// TODO add multicall?

/// @title StakingMiddleware
/// @notice This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.
contract StakingMiddleware is Notifier, IStakingMiddleware {
    constructor(IUniStaker unistaker_, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
        Notifier('UVN Staking Middleware', 'UVN')
    {}

    /// @inheritdoc Nonces
    function nonces(address owner) public view override(Nonces, IStakingMiddleware) returns (uint256) {
        return super.nonces(owner);
    }
}
