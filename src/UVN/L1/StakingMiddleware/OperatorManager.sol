// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IOperatorManager} from '../../../interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol';
import {ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';
import {Nonces, Votes} from './libraries/Votes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

abstract contract OperatorManager is Votes, ProtocolRewardDistributor, IOperatorManager {
    constructor() EIP712('UVN-StakingMiddleware', '1') {}

    function _afterDeposit(address delegator, uint96 amount) internal virtual override {
        super._afterDeposit(delegator, amount);
        address operator = delegates(delegator);
        if (operator != address(0)) {
            _transferVotingUnits(address(0), operator, amount);
        }
    }

    function _afterWithdrawal(address delegator, uint96 amount) internal virtual override {
        super._afterWithdrawal(delegator, amount);
        address operator = delegates(delegator);
        if (operator != address(0)) {
            _transferVotingUnits(operator, address(0), amount);
        }
    }

    function _delegate(address delegator, address operator) internal override {
        if (operator == address(0)) {
            _deselectOperator(delegator);
        } else {
            _selectOperator(delegator, operator);
        }
        super._delegate(delegator, operator);
    }

    function _selectOperator(address delegator, address operator) internal {
        _beforeOperatorSelection(delegator, operator);
        if (delegates(delegator) != address(0)) revert IOperatorManager.OperatorAlreadySelected();
        _afterOperatorSelection(delegator, operator);
    }

    // TODO withdrawal delay
    function _deselectOperator(address delegator) internal {
        _beforeOperatorDeselection(delegator);
        if (delegates(delegator) == address(0)) revert IOperatorManager.NoOperatorSelected();
        _afterOperatorDeselection(delegator);
    }

    function _getVotingUnits(address delegator) internal view virtual override returns (uint256) {
        return _delegatorStake(delegator);
    }

    function _beforeOperatorSelection(address delegator, address operator) internal virtual {}

    function _afterOperatorSelection(address delegator, address operator) internal virtual {}

    function _beforeOperatorDeselection(address delegator) internal virtual {}

    function _afterOperatorDeselection(address delegator) internal virtual {}
}
