// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {OperatorManager} from './OperatorManager.sol';

abstract contract SlashingManager is OperatorManager {
    uint96 private constant PERCENTAGE_DENOMINATOR = 1e18;

    struct SlashingInstance {
        uint96 remainingPercentage;
        bytes32 next;
    }

    struct SlashingData {
        bytes32 head;
        bytes32 tail;
        mapping(bytes32 instanceHash => SlashingInstance instance) instances;
    }

    mapping(address operator => SlashingData data) internal _slashingData;
    mapping(address delegator => bytes32 operatorTail) internal _delegatorSlashingHead;

    function selectOperator(address operator) public override {
        super.selectOperator(operator);
        _delegatorSlashingHead[msg.sender] = _slashingData[operator].tail;
    }

    function deselectOperator() public override {
        super.deselectOperator();
        _delegatorSlashingHead[msg.sender] = bytes32(0);
    }

    function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE()) {
        require(amount != 0);
        uint96 stakeBefore = uint96(_operatorTotalStake[operator]);
        _operatorTotalStake[operator] -= amount;
        uint96 remainingPercentage = ((stakeBefore - amount) * PERCENTAGE_DENOMINATOR) / stakeBefore;
        _slash(operator, remainingPercentage);
    }

    function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE()) {
        require(percentage != 0);
        require(percentage <= PERCENTAGE_DENOMINATOR);
        _operatorTotalStake[operator] -= (_operatorTotalStake[operator] * percentage) / PERCENTAGE_DENOMINATOR;
        _slash(operator, PERCENTAGE_DENOMINATOR - percentage);
    }

    function applySlashing(address delegator, uint256 n) public {
        (uint96 newStake, bytes32 delegatorHead) = _calculateSlashing(delegator, n);
        _delegatorSlashingHead[delegator] = delegatorHead;
        _depositorData[delegator].stake = newStake;
        // TODO send slashed funds to slashing beneficiary
    }

    function isDelegatorSlashed(address delegator) external view returns (bool) {
        address operator = _operator(delegator);
        if (operator == address(0)) return false;
        bytes32 delegatorHead = _delegatorSlashingHead[delegator];
        bytes32 operatorTail = _slashingData[operator].tail;
        return _isDelegatorSlashed(operatorTail, delegatorHead);
    }

    function delegatorStake(address delegator) public view override returns (uint96) {
        (uint96 newStake,) = _calculateSlashing(delegator, type(uint256).max);
        return newStake;
    }

    function _slash(address operator, uint96 remainingPercentage) internal {
        SlashingInstance memory instance =
            SlashingInstance({remainingPercentage: remainingPercentage, next: bytes32(0)});
        bytes32 instanceHash = keccak256(abi.encode(instance));
        _slashingData[operator].instances[instanceHash] = instance;
        _slashingData[operator].instances[_slashingData[operator].tail].next = instanceHash;
        _slashingData[operator].tail = instanceHash;
        // TODO notify delegation manager about slashing event
    }

    function _calculateSlashing(address delegator, uint256 n)
        internal
        view
        returns (uint96 newStake, bytes32 delegatorHead)
    {
        address operator = _operator(delegator);
        newStake = super.delegatorStake(delegator);
        if (operator == address(0)) return (newStake, bytes32(0));
        delegatorHead = _delegatorSlashingHead[delegator];
        SlashingData storage data = _slashingData[operator];
        bytes32 operatorTail = data.tail;
        if (!_isDelegatorSlashed(operatorTail, delegatorHead)) return (newStake, delegatorHead);
        uint256 i = 0;
        delegatorHead = data.instances[delegatorHead].next;
        while (i < n) {
            SlashingInstance memory instance = data.instances[delegatorHead];
            newStake = (newStake * instance.remainingPercentage) / PERCENTAGE_DENOMINATOR;
            if (_isDelegatorSlashed(operatorTail, instance.next)) break;
            delegatorHead = instance.next;
            i++;
        }
    }

    function _isDelegatorSlashed(bytes32 operatorTail, bytes32 delegatorHead) internal pure returns (bool) {
        return operatorTail != delegatorHead;
    }

    function SLASHER_ROLE() public view returns (bytes32) {
        return keccak256(abi.encodePacked('SLASHER_ROLE', delegationManager()));
    }
}
