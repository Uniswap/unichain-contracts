// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IOperatorManager} from '../../../interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol';
import {ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';
import {StakeManager} from './StakeManager.sol';
import {OperatorVotes} from './libraries/OperatorVotes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

/// @title OperatorManager - Base contract for the StakingMiddleware
/// @notice This contract manages the selection of operators by delegators. The selection of operators implements the `IVotes` interface. Before a delegator can undelegate from an operator, they must pass a delay period. During this delay period their voting power is set to 0 but they remain slashable until the undelegation is finalized.
abstract contract OperatorManager is OperatorVotes, ProtocolRewardDistributor, IOperatorManager {
    /// @dev Storage for data required to finalize an undelegation
    struct UndelegationData {
        /// @dev The operator the delegator was delegating to
        address operator;
        /// @dev The timestamp at which the undelegation will be finalized
        uint96 timestamp;
    }

    mapping(address operator => uint256 amount) private _slashableStakes;
    mapping(address delegator => UndelegationData undelegationData) private _undelegationData;

    constructor() EIP712('UVN-StakingMiddleware', '1') {}

    /// @dev After a delegator stakes, increase the operator's voting power immediately and increase the slashable stake
    function _afterStake(address delegator, uint96 amount) internal virtual override {
        super._afterStake(delegator, amount);
        address operator = delegates(delegator);
        if (operator != address(0)) {
            _slashableStakes[operator] += amount;
            _transferVotingUnits(address(0), delegator, amount);
        }
    }

    /// @dev After a delegator unstakes their stake, decrease the operator's voting power immediately
    function _afterUnstake(address delegator, uint96 amount) internal virtual override {
        super._afterUnstake(delegator, amount);
        address operator = delegates(delegator);
        if (operator != address(0)) {
            _transferVotingUnits(delegator, address(0), amount);
        }
    }

    /// @dev After a delegator withdraws their unstaked stake, decrease the slashable stake of the operator
    function _afterWithdraw(address delegator, uint96 amount) internal virtual override {
        super._afterWithdraw(delegator, amount);
        _slashableStakes[delegates(delegator)] -= amount;
    }

    /// @inheritdoc IOperatorManager
    function announceOperatorUndelegation() external {
        address operator = delegates(msg.sender);
        if (_undelegationData[msg.sender].operator != address(0)) {
            revert UndelegationNotFinalized(_undelegationData[msg.sender].timestamp);
        }
        if (operator == address(0)) revert NoOperatorSelected();
        _beforeOperatorUndelegationAnnouncement(msg.sender);
        uint96 undelegateAt = uint96(block.timestamp + withdrawalDelay());
        _undelegationData[msg.sender] = UndelegationData({operator: operator, timestamp: undelegateAt});
        super._delegate(msg.sender, address(0));
        emit OperatorUndelegationAnnounced(msg.sender, operator, undelegateAt);
        _afterOperatorUndelegationAnnouncement(msg.sender);
    }

    /// @inheritdoc IOperatorManager
    function slashableOperatorStake(address operator) public view returns (uint96) {
        return uint96(_slashableStakes[operator]);
    }

    /// @dev Manages the delegation/undelegation of a delegator to an operator. If the operator is set to `address(0)`, the delegator is undelegated from their current operator. Otherwise, the delegator is delegated to the new operator.
    function _delegate(address delegator, address operator) internal override {
        if (operator == address(0)) {
            _deselectOperator(delegator);
        } else {
            _selectOperator(delegator, operator);
            super._delegate(delegator, operator);
            _afterOperatorSelection(delegator, operator);
        }
    }

    /// @dev Delegates a delegator's stake to an operator, the delegator must not be already delegating to an operator and must have any pending undelegation finalized
    function _selectOperator(address delegator, address operator) internal {
        if (delegates(delegator) != address(0)) revert OperatorAlreadySelected();
        uint256 undelegateAt = _undelegationData[delegator].timestamp;
        if (undelegateAt > block.timestamp) {
            revert UndelegationNotFinalized(undelegateAt);
        }
        _beforeOperatorSelection(delegator, operator);
        _slashableStakes[operator] += _slashableStake(delegator);
    }

    /// @dev Undelegates a delegator from an operator, the delegator must first announce their intention to undelegate by calling `announceOperatorUndelegation`. This function can only be called once the delay has passed.
    function _deselectOperator(address delegator) internal {
        address operator = delegates(delegator);
        UndelegationData memory undelegationData = _undelegationData[delegator];
        // delegator is not delegating and has no pending undelegation
        if (undelegationData.operator == address(0) && operator == address(0)) revert NoOperatorSelected();
        if (undelegationData.timestamp > block.timestamp) {
            revert UndelegationNotFinalized(undelegationData.timestamp);
        }
        _beforeOperatorDeselection(delegator);
        _slashableStakes[undelegationData.operator] -= _slashableStake(delegator);
        _undelegationData[delegator] = UndelegationData({operator: address(0), timestamp: 0});
        _afterOperatorDeselection(delegator);
    }

    function _slashOperatorVotes(address operator, uint256 remainingPercentage) internal virtual {
        _slashableStakes[operator] = _slashableStakes[operator] * remainingPercentage / PERCENTAGE_DENOMINATOR;
        uint256 newVotes = getVotes(operator) * remainingPercentage / PERCENTAGE_DENOMINATOR;
        _updateOperatorVotesAfterSlashing(operator, uint96(newVotes));
    }

    function _getVotingUnits(address delegator) internal view virtual override returns (uint256) {
        return _delegatorStake(delegator);
    }

    // TODO rename to _beforeOperatorDelegation?
    function _beforeOperatorSelection(address delegator, address operator) internal virtual {}

    function _afterOperatorSelection(address delegator, address operator) internal virtual {}

    function _beforeOperatorUndelegationAnnouncement(address delegator) internal virtual {}

    function _afterOperatorUndelegationAnnouncement(address delegator) internal virtual {}

    // TODO rename to _beforeOperatorUndelegation?
    function _beforeOperatorDeselection(address delegator) internal virtual {}

    function _afterOperatorDeselection(address delegator) internal virtual {}
}
