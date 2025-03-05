// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DepositorData, IStakingMiddleware} from '../../interfaces/UVN/L1/IStakingMiddleware.sol';

import {IUniStaker} from '../../interfaces/UVN/L1/IUnistaker.sol';

import {ProtocolRewardDistributor} from './StakingMiddleware/ProtocolRewardDistributor.sol';
import {StakingMiddlewareParams} from './StakingMiddleware/StakingMiddlewareParams.sol';
import {UniStakerWrapper} from './StakingMiddleware/UniStakerWrapper.sol';
// TODO add multicall?

contract StakingMiddleware is ProtocolRewardDistributor, StakingMiddlewareParams, IStakingMiddleware {
    mapping(address delegator => DepositorData data) internal _depositorData;
    mapping(address operator => uint256 totalStake) internal _operatorTotalStake;

    uint256 public totalStake;

    constructor(address initialAdmin, IUniStaker unistaker_, uint256 withdrawalDelay_)
        UniStakerWrapper(unistaker_)
        StakingMiddlewareParams(initialAdmin, withdrawalDelay_)
    {}

    function updateGovernanceDelegatee(address newGovernanceDelegatee) external {
        _depositIntoUniStaker(0, newGovernanceDelegatee);
    }

    function deposit(uint256 amount) external {
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        stakeToken.transferFrom(msg.sender, address(this), amount);
        DepositorData storage data = _depositorData[msg.sender];
        data.stake += amount;
        totalStake += amount;
        if (_isDepositedIntoUniStaker(msg.sender)) {
            _updateRewardCheckpoint(msg.sender);
            _depositIntoUniStaker(amount, address(0));
        }
        if (data.selectedOperator != address(0)) {
            _operatorTotalStake[data.selectedOperator] += amount;
        }
    }

    function depositIntoUniStaker(address governanceDelegatee) external {
        if (_isDepositedIntoUniStaker(msg.sender)) revert AlreadyDepositedIntoUniStaker();
        _updateRewardCheckpoint(msg.sender);
        _depositIntoUniStaker(_depositorData[msg.sender].stake, governanceDelegatee);
    }

    function withdrawFromUniStaker() external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        _updateRewardCheckpoint(msg.sender);
        _withdrawFromUniStaker(_depositorData[msg.sender].stake);
    }

    function alterGovernanceDelegatee(address newGovernanceDelegatee) external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        _depositIntoUniStaker(0, newGovernanceDelegatee);
    }

    // TODO withdrawal delay
    function withdraw(uint256 amount) external {
        DepositorData storage data = _depositorData[msg.sender];
        data.stake -= amount;
        totalStake -= amount;
        if (_isDepositedIntoUniStaker(msg.sender)) {
            _updateRewardCheckpoint(msg.sender);
            _withdrawFromUniStaker(amount);
        }
        if (data.selectedOperator != address(0)) {
            _operatorTotalStake[data.selectedOperator] -= amount;
        }
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        stakeToken.transfer(msg.sender, amount);
    }

    function selectOperator(address operator) external {
        DepositorData storage data = _depositorData[msg.sender];
        if (data.selectedOperator != address(0)) revert OperatorAlreadySelected();
        data.selectedOperator = operator;
        _operatorTotalStake[operator] += _stakedBalanceOf(msg.sender);
    }

    // TODO withdrawal delay
    function deselectOperator() external {
        DepositorData storage data = _depositorData[msg.sender];
        if (data.selectedOperator == address(0)) revert NoOperatorSelected();
        _operatorTotalStake[data.selectedOperator] -= _stakedBalanceOf(msg.sender);
        data.selectedOperator = address(0);
    }
}
