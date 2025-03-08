// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {OperatorManager} from './OperatorManager.sol';
import {ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';

abstract contract SlashingManager is ProtocolRewardDistributor, OperatorManager {
    uint96 private constant PERCENTAGE_DENOMINATOR = 1e18;

    struct SlashingInstance {
        uint96 remainingPercentage;
        uint40 timestamp;
        uint256 rewardCheckpoint;
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

    function deselectOperator() public virtual override {
        super.deselectOperator();
        _delegatorSlashingHead[msg.sender] = bytes32(0);
    }

    function withdrawRewards(address to) public override returns (uint256 reward) {
        applySlashing(msg.sender, type(uint256).max);
        return super.withdrawRewards(to);
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
        uint256 globalRewardCheckpoint = _updateGlobalRewardCheckpoint();
        (uint96 newStake, bytes32 delegatorHead, uint256 newRewards, uint256 slashedRewards, uint256 newCheckpoint) =
            _calculateSlashing(delegator, n, globalRewardCheckpoint);
        _delegatorSlashingHead[delegator] = delegatorHead;
        uint96 slashedStake = _depositorData[delegator].stake - newStake;
        _depositorData[delegator].stake = newStake;
        if (newRewards != 0) {
            _earnedRewardsOf[delegator] += newRewards;
            _rewardCheckpointOf[delegator] = newCheckpoint;
        }
        if (slashedRewards != 0) {
            rewardToken.transfer(slashingBeneficiary(), slashedRewards);
        }
        if (_isDepositedIntoUniStaker(delegator)) {
            _withdrawFromUniStaker(delegator, slashedStake);
        }
        stakeToken.transfer(slashingBeneficiary(), slashedStake);
    }

    function isDelegatorSlashed(address delegator) external view returns (bool) {
        address operator = _operator(delegator);
        if (operator == address(0)) return false;
        bytes32 delegatorHead = _delegatorSlashingHead[delegator];
        bytes32 operatorTail = _slashingData[operator].tail;
        return _isDelegatorSlashed(operatorTail, delegatorHead);
    }

    function delegatorStake(address delegator) public view override returns (uint96) {
        (uint96 newStake,,,,) = _calculateSlashing(delegator, type(uint256).max, _globalRewardCheckpoint);
        return newStake;
    }

    function rewardsOf(address delegator) public view override returns (uint256) {
        uint256 unclaimedGlobalReward = unistaker.unclaimedReward(address(this));
        uint256 globalCheckpoint = _getNewGlobalRewardCheckpoint(unclaimedGlobalReward);
        (uint256 newStake,, uint256 newRewards,, uint256 newCheckpoint) =
            _calculateSlashing(delegator, type(uint256).max, globalCheckpoint);
        return
            _earnedRewardsOf[delegator] + newRewards + _calculateRewardFromTo(newStake, newCheckpoint, globalCheckpoint);
    }

    function _slash(address operator, uint96 remainingPercentage) internal {
        uint256 globalRewardCheckpoint = _updateGlobalRewardCheckpoint();
        SlashingInstance memory instance = SlashingInstance({
            remainingPercentage: remainingPercentage,
            timestamp: uint40(block.timestamp),
            rewardCheckpoint: globalRewardCheckpoint,
            next: bytes32(0)
        });
        bytes32 instanceHash = keccak256(abi.encode(instance));
        _slashingData[operator].instances[instanceHash] = instance;
        _slashingData[operator].instances[_slashingData[operator].tail].next = instanceHash;
        _slashingData[operator].tail = instanceHash;
        // TODO notify delegation manager about slashing event
    }

    /// @dev iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.
    /// @dev In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.
    function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
        internal
        view
        returns (
            uint96 newStake,
            bytes32 delegatorHead,
            uint256 newRewards,
            uint256 slashedRewards,
            uint256 newCheckpoint
        )
    {
        address operator = _operator(delegator);
        newStake = super.delegatorStake(delegator);
        newCheckpoint = _rewardCheckpointOf[delegator];
        // user not delegated to an operator
        if (operator == address(0)) return (newStake, bytes32(0), 0, 0, newCheckpoint);
        delegatorHead = _delegatorSlashingHead[delegator];
        SlashingData storage data = _slashingData[operator];
        bytes32 operatorTail = data.tail;
        if (!_isDelegatorSlashed(operatorTail, delegatorHead)) return (newStake, delegatorHead, 0, 0, newCheckpoint);
        bool isDeposited = _isDepositedIntoUniStaker(delegator);
        if (isDeposited) {
            slashedRewards = _calculateRewardFromTo(newStake, newCheckpoint, globalCheckpoint);
        }
        uint256 i = 0;
        delegatorHead = data.instances[delegatorHead].next;
        while (i < n) {
            SlashingInstance memory instance = data.instances[delegatorHead];
            if (isDeposited) {
                newRewards += _calculateRewardFromTo(newStake, newCheckpoint, instance.rewardCheckpoint);
                newCheckpoint = instance.rewardCheckpoint;
            }
            newStake = (newStake * instance.remainingPercentage) / PERCENTAGE_DENOMINATOR;
            if (_isDelegatorSlashed(operatorTail, instance.next)) break;
            delegatorHead = instance.next;
            i++;
        }
        if (isDeposited) {
            // calculate the remaining rewards from the last slashing instance until now
            newRewards += _calculateRewardFromTo(newStake, newCheckpoint, globalCheckpoint);
            slashedRewards -= newRewards;
            newCheckpoint = globalCheckpoint;
        }
    }

    function _isDelegatorSlashed(bytes32 operatorTail, bytes32 delegatorHead) internal pure returns (bool) {
        return operatorTail != delegatorHead;
    }

    function SLASHER_ROLE() public view returns (bytes32) {
        return keccak256(abi.encodePacked('SLASHER_ROLE', delegationManager()));
    }
}
