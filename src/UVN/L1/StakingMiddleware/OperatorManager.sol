// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IOperatorManager} from '../../../interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol';
import {ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';
import {Nonces, Votes} from './libraries/Votes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

abstract contract OperatorManager is Votes, ProtocolRewardDistributor, IOperatorManager {
    constructor() EIP712('UVN-StakingMiddleware', '1') {}

    mapping(address operator => uint256 amount) private _slashableStakes;
    mapping(address delegator => uint256 undelegationTimestamp) private _undelegationTimestamp;

    function _afterStake(address delegator, uint96 amount) internal virtual override {
        super._afterStake(delegator, amount);
        address operator = delegates(delegator);
        if (operator != address(0)) {
            _slashableStakes[operator] += amount;
            _transferVotingUnits(address(0), operator, amount);
        }
    }

    function _afterUnstake(address delegator, uint96 amount) internal virtual override {
        super._afterUnstake(delegator, amount);
        address operator = delegates(delegator);
        if (operator != address(0)) {
            _transferVotingUnits(operator, address(0), amount);
        }
    }

    function _afterWithdraw(address delegator, uint96 amount) internal virtual override {
        super._afterWithdraw(delegator, amount);
        _slashableStakes[delegates(delegator)] -= amount;
    }

    /// @inheritdoc IOperatorManager
    function announceOperatorUndelegation() external {
        address operator = delegates(msg.sender);
        if (operator == address(0)) revert NoOperatorSelected();
        _beforeOperatorUndelegationAnnouncement(msg.sender);
        uint256 undelegateAt = block.timestamp + withdrawalDelay();
        _undelegationTimestamp[msg.sender] = undelegateAt;
        super._delegate(msg.sender, address(0));
        emit OperatorUndelegationAnnounced(msg.sender, operator, undelegateAt);
        _afterOperatorUndelegationAnnouncement(msg.sender);
    }

    /// @inheritdoc IOperatorManager
    function slashableOperatorStake(address operator) public view returns (uint96) {
        return uint96(_slashableStakes[operator]);
    }

    function _delegate(address delegator, address operator) internal override {
        if (operator == address(0)) {
            _deselectOperator(delegator);
        } else {
            _selectOperator(delegator, operator);
            super._delegate(delegator, operator);
        }
    }

    function _selectOperator(address delegator, address operator) internal {
        _beforeOperatorSelection(delegator, operator);
        if (delegates(delegator) != address(0)) revert OperatorAlreadySelected();
        uint256 undelegateAt = _undelegationTimestamp[delegator];
        if (undelegateAt > block.timestamp) {
            revert UndelegationNotFinalized(undelegateAt);
        }
        _slashableStakes[operator] += _slashableStake(delegator);
        _afterOperatorSelection(delegator, operator);
    }

    function _deselectOperator(address delegator) internal {
        _beforeOperatorDeselection(delegator);
        address operator = delegates(delegator);
        if (operator == address(0)) revert NoOperatorSelected();
        uint256 undelegateAt = _undelegationTimestamp[delegator];
        if (undelegateAt > block.timestamp) {
            revert UndelegationNotFinalized(undelegateAt);
        }
        _slashableStakes[operator] -= _slashableStake(delegator);
        _afterOperatorDeselection(delegator);
    }

    function _slashOperatorVotes(address operator, uint256 remainingPercentage) internal virtual {
        _slashableStakes[operator] = _slashableStakes[operator] * remainingPercentage / PERCENTAGE_DENOMINATOR;
        uint256 newVotes = getVotes(operator) * remainingPercentage / PERCENTAGE_DENOMINATOR;
        Votes._updateOperatorVotesAfterSlashing(operator, uint96(newVotes));
    }

    function _getVotingUnits(address delegator) internal view virtual override returns (uint256) {
        return _delegatorStake(delegator);
    }

    function _beforeOperatorSelection(address delegator, address operator) internal virtual {}

    function _afterOperatorSelection(address delegator, address operator) internal virtual {}

    function _beforeOperatorUndelegationAnnouncement(address delegator) internal virtual {}

    function _afterOperatorUndelegationAnnouncement(address delegator) internal virtual {}

    function _beforeOperatorDeselection(address delegator) internal virtual {}

    function _afterOperatorDeselection(address delegator) internal virtual {}
}
