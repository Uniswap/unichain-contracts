// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddleware} from '../../interfaces/UVN/L1/IStakingMiddleware.sol';

import {IUniStaker} from '../../interfaces/UVN/L1/IUnistaker.sol';

import {ProtocolRewardDistributor} from './StakingMiddleware/ProtocolRewardDistributor.sol';
import {StakingMiddlewareParams} from './StakingMiddleware/StakingMiddlewareParams.sol';
import {UniStakerWrapper} from './StakingMiddleware/UniStakerWrapper.sol';
// TODO add multicall?

contract StakingMiddleware is ProtocolRewardDistributor, StakingMiddlewareParams, IStakingMiddleware {
    mapping(address delegator => address operator) internal _selectedOperators;
    mapping(address operator => uint256 totalStake) internal _operatorTotalStake;

    constructor(address initialAdmin, IUniStaker unistaker_, uint256 withdrawalDelay_)
        UniStakerWrapper(unistaker_)
        StakingMiddlewareParams(initialAdmin, withdrawalDelay_)
    {}

    function updateGovernanceDelegatee(address newGovernanceDelegatee) external {
        _depositIntoUniStaker(0, newGovernanceDelegatee);
    }

    function deposit(uint256 amount, address governanceDelegatee) external {
        _updateRewardCheckpoint(msg.sender);
        _depositIntoUniStaker(amount, governanceDelegatee);
        address operator = _selectedOperators[msg.sender];
        if (operator != address(0)) {
            _operatorTotalStake[operator] += amount;
        }
    }

    // TODO withdrawal delay
    function withdraw(uint256 amount) external {
        _updateRewardCheckpoint(msg.sender);
        _withdrawFromUniStaker(amount);
        address operator = _selectedOperators[msg.sender];
        if (operator != address(0)) {
            _operatorTotalStake[operator] -= amount;
        }
    }

    function selectOperator(address operator) external {
        address currentOperator = _selectedOperators[msg.sender];
        if (currentOperator != address(0)) revert OperatorAlreadySelected();
        _selectedOperators[msg.sender] = operator;
        _operatorTotalStake[operator] += _stakedBalanceOf(msg.sender);
    }

    // TODO withdrawal delay
    function deselectOperator() external {
        address operator = _selectedOperators[msg.sender];
        if (operator == address(0)) revert NoOperatorSelected();
        _operatorTotalStake[operator] -= _stakedBalanceOf(msg.sender);
        _selectedOperators[msg.sender] = address(0);
    }
}
