// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IProtocolRewardDistributor} from './StakingMiddleware/IProtocolRewardDistributor.sol';
import {IStakingMiddlewareParams} from './StakingMiddleware/IStakingMiddlewareParams.sol';

struct DepositorData {
    address selectedOperator;
    uint256 stake;
}

interface IStakingMiddleware is IProtocolRewardDistributor, IStakingMiddlewareParams {
    error OperatorAlreadySelected();
    error NoOperatorSelected();
    error AlreadyDepositedIntoUniStaker();
    error NotDepositedIntoUniStaker();
}
