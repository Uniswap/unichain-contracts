// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ISlashingManager} from '../../../interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol';
import {OperatorManager} from './OperatorManager.sol';
import {IProtocolRewardDistributor, ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';
import {StakeManager} from './StakeManager.sol';

abstract contract SlashingManager is OperatorManager, ISlashingManager {
    struct SlashingInstance {
        uint96 remainingPercentage;
        uint256 rewardCheckpoint;
    }

    mapping(address operator => SlashingInstance[] instances) internal _slashingInstances;
    mapping(address delegator => uint256 instanceLength) internal _delegatorInstanceLengths;

    function _afterOperatorSelection(address delegator, address operator) internal virtual override {
        super._afterOperatorSelection(delegator, operator);
        _delegatorInstanceLengths[delegator] = _slashingInstances[operator].length;
    }

    function _afterOperatorDeselection(address delegator) internal virtual override {
        super._afterOperatorDeselection(delegator);
        _delegatorInstanceLengths[delegator] = 0;
    }

    function _beforeStake(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeStake(delegator, amount);
    }

    function _beforeUnstake(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUnstake(delegator, amount);
    }

    function _beforeWithdraw(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeWithdraw(delegator, amount);
    }

    function _beforeUniStakerDeposit(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerDeposit(delegator, amount);
    }

    function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerWithdrawal(delegator, amount);
    }

    function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerDelegateChange(delegator, newGovernanceDelegatee);
    }

    function _beforeRewardsWithdrawal(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeRewardsWithdrawal(delegator);
    }

    function _beforeOperatorUndelegationAnnouncement(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeOperatorUndelegationAnnouncement(delegator);
    }

    function _beforeOperatorDeselection(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeOperatorDeselection(delegator);
    }

    /// @inheritdoc ISlashingManager
    function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE()) {
        if (amount == 0) revert SlashingAmountZero();
        // TODO that amount does not exceed the total operator stake
        uint96 stakeBefore = slashableOperatorStake(operator);
        _slashOperatorVotes(operator, amount);
        uint96 remainingPercentage = ((stakeBefore - amount) * PERCENTAGE_DENOMINATOR) / stakeBefore;
        _slash(operator, remainingPercentage);
    }

    /// @inheritdoc ISlashingManager
    function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE()) {
        if (percentage > PERCENTAGE_DENOMINATOR) revert SlashingPercentageTooHigh();
        uint96 stakeBefore = slashableOperatorStake(operator);
        uint96 amount = (stakeBefore * percentage) / PERCENTAGE_DENOMINATOR;
        if (amount == 0) revert SlashingAmountZero();
        _slashOperatorVotes(operator, amount);
        _slash(operator, PERCENTAGE_DENOMINATOR - percentage);
    }

    /// @inheritdoc ISlashingManager
    function applySlashing(address delegator, uint256 n) public {
        if (n == 0) return;
        uint256 globalRewardCheckpoint = _updateGlobalRewardCheckpoint();
        (
            bool slashed,
            uint96 newStake,
            uint256 delegatorInstanceLength,
            uint256 newRewards,
            uint256 slashedRewards,
            uint256 newCheckpoint
        ) = _calculateSlashing(delegator, n, globalRewardCheckpoint);
        _delegatorInstanceLengths[delegator] = delegatorInstanceLength;
        if (!slashed) return;
        uint96 slashedStake = StakeManager._delegatorStake(delegator) - newStake;
        if (newRewards != 0) {
            _distributeRewards(delegator, newRewards, newCheckpoint);
        }
        if (slashedRewards != 0) {
            REWARD_TOKEN.transfer(slashingBeneficiary(), slashedRewards);
        }
        _slashDelegatorStake(delegator, slashedStake);
    }

    /// @inheritdoc ISlashingManager
    function slashingPendingForDelegator(address delegator) external view returns (bool) {
        address operator = delegates(delegator);
        if (operator == address(0)) return false;
        uint256 delegatorInstanceLength = _delegatorInstanceLengths[delegator];
        uint256 operatorLength = _slashingInstances[operator].length;
        return _isDelegatorSlashed(delegatorInstanceLength, operatorLength);
    }

    function rewardsOf(address delegator)
        public
        view
        override(ProtocolRewardDistributor, IProtocolRewardDistributor)
        returns (uint256)
    {
        uint256 unclaimedGlobalReward = UNISTAKER.unclaimedReward(address(this));
        uint256 globalCheckpoint = _getNewGlobalRewardCheckpoint(unclaimedGlobalReward);
        (, uint256 newStake,, uint256 newRewards,, uint256 newCheckpoint) =
            _calculateSlashing(delegator, type(uint256).max, globalCheckpoint);
        return
            _earnedRewardsOf[delegator] + newRewards + _calculateRewardFromTo(newStake, newCheckpoint, globalCheckpoint);
    }

    // @audit can introduce minor inconsistencies between the sum of all remaining balances and the the recorded total stake due to rounding errors
    function _slash(address operator, uint96 remainingPercentage) internal {
        uint256 globalRewardCheckpoint = _updateGlobalRewardCheckpoint();
        SlashingInstance memory instance =
            SlashingInstance({remainingPercentage: remainingPercentage, rewardCheckpoint: globalRewardCheckpoint});
        _slashingInstances[operator].push(instance);
        // TODO notify delegation manager about slashing event
    }

    function _delegatorStake(address delegator) internal view override returns (uint96) {
        (, uint96 newStake,,,,) = _calculateSlashing(delegator, type(uint256).max, _globalRewardCheckpoint);
        return newStake;
    }

    /// @dev iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.
    /// @dev In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.
    function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
        internal
        view
        returns (
            bool slashed,
            uint96 newStake,
            uint256 delegatorLength,
            uint256 newRewards,
            uint256 slashedRewards,
            uint256 newCheckpoint
        )
    {
        address operator = delegates(delegator);
        newStake = StakeManager._delegatorStake(delegator);
        newCheckpoint = _rewardCheckpointOf[delegator];
        // user not delegated to an operator
        if (operator == address(0)) return (slashed, newStake, 0, 0, 0, newCheckpoint);
        delegatorLength = _delegatorInstanceLengths[delegator];
        uint256 operatorLength = _slashingInstances[operator].length;
        if (!_isDelegatorSlashed(delegatorLength, operatorLength)) {
            return (slashed, newStake, delegatorLength, 0, 0, newCheckpoint);
        }
        slashed = true;
        bool isDeposited = _isDepositedIntoUniStaker(delegator);
        if (isDeposited) {
            slashedRewards = _calculateRewardFromTo(newStake, newCheckpoint, globalCheckpoint);
        }
        uint256 i = 0;
        while (i < n) {
            SlashingInstance memory instance = _slashingInstances[operator][delegatorLength];
            if (isDeposited) {
                newRewards += _calculateRewardFromTo(newStake, newCheckpoint, instance.rewardCheckpoint);
                newCheckpoint = instance.rewardCheckpoint;
            }
            newStake = (newStake * instance.remainingPercentage) / PERCENTAGE_DENOMINATOR;
            if (!_isDelegatorSlashed(++delegatorLength, operatorLength)) break;
            i++;
        }
        if (isDeposited) {
            // calculate the remaining rewards from the last slashing instance until now
            newRewards += _calculateRewardFromTo(newStake, newCheckpoint, globalCheckpoint);
            slashedRewards -= newRewards;
            newCheckpoint = globalCheckpoint;
        }
    }

    function _isDelegatorSlashed(uint256 delegatorInstanceLength, uint256 operatorLength)
        internal
        pure
        returns (bool)
    {
        return delegatorInstanceLength < operatorLength;
    }

    /// TODO invalidation of group of slashers?
    function SLASHER_ROLE() public pure returns (bytes32) {
        return keccak256('SLASHER_ROLE');
    }
}
