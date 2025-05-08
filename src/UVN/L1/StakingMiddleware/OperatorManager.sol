// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IOperatorManager} from '../../../interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol';
import {ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';
import {OperatorVotes} from './libraries/OperatorVotes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

/// @title OperatorManager - Base contract for the StakingMiddleware
/// @notice This contract manages the selection of operators by delegators. The selection of operators implements the `IVotes` interface. Before a delegator can undelegate from an operator, they must pass a delay period. During this delay period their voting power is set to 0 but they remain slashable until the undelegation is finalized.
abstract contract OperatorManager is OperatorVotes, ProtocolRewardDistributor, IOperatorManager {
    /// @dev Storage for data required to finalize an undelegation
    struct UndelegationData {
        /// @dev The operator the delegator was delegating to
        address operator;
        /// @dev The timestamp at which the undelegation can be finalized
        uint96 undelegateAt;
    }

    mapping(address operator => uint256 amount) private _slashableStakes;
    mapping(address delegator => UndelegationData undelegationData) private _undelegationData;

    constructor(string memory name) EIP712(name, '1') {}

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
        address operator = delegates(delegator);
        if (operator != address(0)) {
            _slashableStakes[operator] -= amount;
        }
    }

    /// @inheritdoc IOperatorManager
    function announceOperatorUndelegation() external {
        address delegator = msg.sender;
        address operator = delegates(delegator);
        if (_undelegationData[delegator].operator != address(0)) {
            revert UndelegationNotFinalized(_undelegationData[delegator].undelegateAt);
        }
        if (operator == address(0)) revert NotDelegated();
        _beforeUndelegationAnnouncement(delegator);
        uint96 undelegateAt = uint96(block.timestamp + withdrawalDelay());
        _undelegationData[delegator] = UndelegationData({operator: operator, undelegateAt: undelegateAt});
        super._delegate(delegator, address(0));
        emit OperatorUndelegationAnnounced(delegator, operator, undelegateAt);
        _afterUndelegationAnnouncement(delegator);
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
            _afterDelegation(delegator, operator);
        }
    }

    /// @dev Delegates a delegator's stake to an operator, the delegator must not be already delegating to an operator and must have any pending undelegation finalized
    function _selectOperator(address delegator, address operator) internal {
        if (delegates(delegator) != address(0)) revert AlreadyDelegated();
        if (_undelegationData[delegator].operator != address(0)) {
            uint256 undelegateAt = _undelegationData[delegator].undelegateAt;
            revert UndelegationNotFinalized(undelegateAt);
        }
        _beforeDelegation(delegator, operator);
        _slashableStakes[operator] += _slashableStake(delegator);
    }

    /// @dev Undelegates a delegator from an operator, the delegator must first announce their intention to undelegate by calling `announceOperatorUndelegation`. This function can only be called once the delay has passed.
    function _deselectOperator(address delegator) internal {
        address operator = delegates(delegator);
        // delegator is already delegating to an operator
        if (operator != address(0)) revert AnnounceUndelegationFirst();
        UndelegationData memory undelegationData = _undelegationData[delegator];
        // delegator is not delegating and has no pending undelegation
        if (undelegationData.operator == address(0)) revert NotDelegated();
        if (undelegationData.undelegateAt > block.timestamp) {
            revert UndelegationNotFinalized(undelegationData.undelegateAt);
        }
        _beforeUndelegation(delegator);
        _slashableStakes[undelegationData.operator] -= _slashableStake(delegator);
        _undelegationData[delegator] = UndelegationData({operator: address(0), undelegateAt: 0});
        _afterUndelegation(delegator);
    }

    function _slashOperatorVotes(address operator, uint256 remainingPercentage) internal virtual {
        _slashableStakes[operator] = _slashableStakes[operator] * remainingPercentage / PERCENTAGE_DENOMINATOR;
        uint256 newVotes = getVotes(operator) * remainingPercentage / PERCENTAGE_DENOMINATOR;
        _updateOperatorVotesAfterSlashing(operator, uint96(newVotes));
        emit OperatorSlashed(operator, uint96(remainingPercentage));
    }

    function _getVotingUnits(address delegator) internal view virtual override returns (uint256) {
        return _delegatorStake(delegator);
    }

    /// @dev Returns the current operator of a delegator, if the delegator has an active undelegation, the operator before the undelegation announcement is returned, otherwise the current operator is returned
    function _slashableOperatorOf(address delegator) internal view returns (address) {
        address undelegationOperator = _undelegationData[delegator].operator;
        if (undelegationOperator != address(0)) return undelegationOperator;
        return delegates(delegator);
    }

    function _beforeDelegation(address delegator, address operator) internal virtual {}

    function _afterDelegation(address delegator, address operator) internal virtual {}

    function _beforeUndelegationAnnouncement(address delegator) internal virtual {}

    function _afterUndelegationAnnouncement(address delegator) internal virtual {}

    function _beforeUndelegation(address delegator) internal virtual {}

    function _afterUndelegation(address delegator) internal virtual {}
}
