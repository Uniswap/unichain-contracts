// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IProtocolRewardDistributor} from './StakingMiddleware/IProtocolRewardDistributor.sol';
import {IStakingMiddlewareParams} from './StakingMiddleware/IStakingMiddlewareParams.sol';

interface IStakingMiddleware is IProtocolRewardDistributor, IStakingMiddlewareParams {
    error AlreadyDepositedIntoUniStaker();
    error NotDepositedIntoUniStaker();
}
