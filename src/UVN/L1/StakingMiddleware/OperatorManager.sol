// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakingMiddlewareParams} from './StakingMiddlewareParams.sol';

struct DepositorData {
    address selectedOperator;
    uint96 stake;
}

abstract contract OperatorManager is StakingMiddlewareParams {
    error OperatorAlreadySelected();
    error NoOperatorSelected();

    mapping(address delegator => DepositorData data) internal _depositorData;
    mapping(address operator => uint256 totalStake) internal _operatorTotalStake;

    function selectOperator(address operator) external {
        DepositorData storage data = _depositorData[msg.sender];
        if (data.selectedOperator != address(0)) revert OperatorAlreadySelected();
        data.selectedOperator = operator;
        _operatorTotalStake[operator] += data.stake;
        delegationManager().mint(msg.sender, data.stake);
        delegationManager().updateDelegatee(msg.sender, operator);
    }

    // TODO withdrawal delay
    function deselectOperator() external {
        DepositorData storage data = _depositorData[msg.sender];
        if (data.selectedOperator == address(0)) revert NoOperatorSelected();
        _operatorTotalStake[data.selectedOperator] -= data.stake;
        data.selectedOperator = address(0);
        delegationManager().updateDelegatee(msg.sender, address(0));
        delegationManager().burn(msg.sender, data.stake);
    }
}
