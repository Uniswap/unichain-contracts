// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ISlashingManager} from '../../../interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol';
import {DelegatorAccessControl} from './DelegatorAccessControl.sol';
import {IProtocolRewardDistributor, ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';
import {StakeManager} from './StakeManager.sol';

/// @title SlashingManager - Base contract for the StakingMiddleware
/// @notice This contract manages the slashing of delegators and operators. When operators are slashed, the slashed amount is converted into the remaining percentage of the operator's slashable delegated stake. The voting power of the operator is updated immediately. As delegators have their own deposits into the UniStaker contract, slashing is applied to the delegator's slashable stake when the delegator next interacts with the StakingMiddleware contract. Slashing can also be applied by anyone at any time. To ensure there isn't an incentive to not stay slashed and continue accruing protocol fees in the UniStaker contract, rewards accrued by the delegator are also slashed.
abstract contract SlashingManager is DelegatorAccessControl, ISlashingManager {
    enum SlashingType {
        NOT_SLASHED,
        PARTIAL_SLASH,
        FULL_SLASH
    }

    struct SlashingInstance {
        uint96 remainingPercentage;
        uint256 rewardCheckpoint;
    }

    struct DelegatorSlashingData {
        /// @dev the length of the slashing instances array of the operator, if the operator is slashed, the delegator length will be < the operator length indicating that a slashing instance has occurred since the delegator was last slashed or delegated to the operator
        uint160 length;
        /// @dev to ensure the rewards are slashed correctly when slashing is applied in multiple tranches, we need to keep track of the slashable stake before the first tranche is applied
        uint96 stakeBeforePartialSlashing;
    }

    mapping(address operator => SlashingInstance[] instances) internal _slashingInstances;
    mapping(address delegator => DelegatorSlashingData data) internal _delegatorSlashingData;

    /// @dev After a delegator selects an operator, store the number of slashing instances an operator had before the delegation to keep track of future slashing instances that occur after the delegation
    function _afterOperatorSelection(address delegator, address operator) internal virtual override {
        super._afterOperatorSelection(delegator, operator);
        _delegatorSlashingData[delegator] =
            DelegatorSlashingData({length: uint160(_slashingInstances[operator].length), stakeBeforePartialSlashing: 0});
    }

    /// @dev After a delegator undelegates from an operator, reset the slashing tracking data for the delegator
    function _afterOperatorDeselection(address delegator) internal virtual override {
        super._afterOperatorDeselection(delegator);
        _delegatorSlashingData[delegator] = DelegatorSlashingData({length: 0, stakeBeforePartialSlashing: 0});
    }

    /// @dev Before a delegator stakes, apply all pending slashing instances to the delegator's stake
    function _beforeStake(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeStake(delegator, amount);
    }

    /// @dev Before a delegator unstakes, apply all pending slashing instances to the delegator's stake
    function _beforeUnstake(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUnstake(delegator, amount);
    }

    /// @dev Before a delegator withdraws, apply all pending slashing instances to the delegator's stake
    function _beforeWithdraw(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeWithdraw(delegator, amount);
    }

    /// @dev Before a delegator deposits into the UniStaker contract, apply all pending slashing instances to the delegator's stake
    function _beforeUniStakerDeposit(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerDeposit(delegator, amount);
    }

    /// @dev Before a delegator withdraws from the UniStaker contract, apply all pending slashing instances to the delegator's stake
    function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerWithdrawal(delegator, amount);
    }

    /// @dev Before a delegator changes their governance delegatee, apply all pending slashing instances to the delegator's stake
    function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerDelegateChange(delegator, newGovernanceDelegatee);
    }

    /// @dev Before a delegator withdraws their rewards, apply all pending slashing instances to the delegator's stake
    function _beforeRewardsWithdrawal(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeRewardsWithdrawal(delegator);
    }

    /// @dev Before a delegator announces their intention to undelegate from an operator, apply all pending slashing instances to the delegator's stake
    function _beforeOperatorUndelegationAnnouncement(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeOperatorUndelegationAnnouncement(delegator);
    }

    /// @dev Before a delegator undelegates from an operator, apply all pending slashing instances to the delegator's stake
    function _beforeOperatorDeselection(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeOperatorDeselection(delegator);
    }

    /// @inheritdoc ISlashingManager
    function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE()) {
        if (amount == 0) revert SlashingAmountZero();
        // TODO that amount does not exceed the total operator stake
        uint96 stakeBefore = slashableOperatorStake(operator);
        uint256 remainingPercentage = ((stakeBefore - amount) * PERCENTAGE_DENOMINATOR) / stakeBefore;
        _slashOperatorVotes(operator, remainingPercentage);
    }

    /// @inheritdoc ISlashingManager
    function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE()) {
        if (percentage > PERCENTAGE_DENOMINATOR) revert SlashingPercentageTooHigh();
        if (percentage == 0) revert SlashingAmountZero();
        _slashOperatorVotes(operator, PERCENTAGE_DENOMINATOR - percentage);
    }

    /// @inheritdoc ISlashingManager
    function applySlashing(address delegator, uint256 n) public {
        if (n == 0) return;
        uint256 globalRewardCheckpoint = _updateGlobalRewardCheckpoint();
        (
            SlashingType slashingType,
            uint256 remainingPercentage,
            uint160 delegatorInstanceLength,
            uint256 newRewards,
            uint256 slashedRewards,
            uint256 newCheckpoint
        ) = _calculateSlashing(delegator, n, globalRewardCheckpoint);
        if (slashingType == SlashingType.NOT_SLASHED) return;
        uint96 stakeBeforePartialSlashing;
        if (slashingType == SlashingType.PARTIAL_SLASH) {
            // partial slash, we keep track of the current slashable stake to ensure the rewards are slashed correctly when the remainder of the slashing instances are applied
            // if this is a subsequent partial slash, we will reuse the stake before the first partial slash
            uint96 currentPartialSlashingStake = _delegatorSlashingData[delegator].stakeBeforePartialSlashing;
            stakeBeforePartialSlashing =
                currentPartialSlashingStake != 0 ? currentPartialSlashingStake : StakeManager._slashableStake(delegator);
        }
        _delegatorSlashingData[delegator] = DelegatorSlashingData({
            length: delegatorInstanceLength,
            stakeBeforePartialSlashing: stakeBeforePartialSlashing
        });
        if (newRewards != 0) {
            _distributeRewards(delegator, newRewards, newCheckpoint);
        }
        if (slashedRewards != 0) {
            REWARD_TOKEN.transfer(slashingBeneficiary(), slashedRewards);
        }
        _slashDelegatorStake(delegator, remainingPercentage);
    }

    /// @inheritdoc ISlashingManager
    function slashingPendingForDelegator(address delegator) external view returns (bool) {
        address operator = delegates(delegator);
        if (operator == address(0)) return false;
        uint256 delegatorInstanceLength = _delegatorSlashingData[delegator].length;
        uint256 operatorLength = _slashingInstances[operator].length;
        return _isDelegatorSlashed(delegatorInstanceLength, operatorLength);
    }

    /// @dev Overrides the `rewardsOf` function in `ProtocolRewardDistributor` to reflect correct rewards for a delegator accounting for slashing
    function rewardsOf(address delegator)
        public
        view
        override(ProtocolRewardDistributor, IProtocolRewardDistributor)
        returns (uint256)
    {
        uint256 unclaimedGlobalReward = UNISTAKER.unclaimedReward(address(this));
        uint256 globalCheckpoint = _getNewGlobalRewardCheckpoint(unclaimedGlobalReward);
        (, uint256 remainingPercentage,, uint256 newRewards,, uint256 newCheckpoint) =
            _calculateSlashing(delegator, type(uint256).max, globalCheckpoint);
        return _earnedRewardsOf[delegator] + newRewards
            + _calculateRewardFromTo(
                _remainingStake(StakeManager._delegatorStake(delegator), remainingPercentage),
                newCheckpoint,
                globalCheckpoint
            );
    }

    // @audit can introduce minor rounding errors between the sum of all remaining balances and the the recorded total stake due to rounding errors
    function _slashOperatorVotes(address operator, uint256 remainingPercentage) internal override {
        uint256 globalRewardCheckpoint = _updateGlobalRewardCheckpoint();
        SlashingInstance memory instance = SlashingInstance({
            remainingPercentage: uint96(remainingPercentage),
            rewardCheckpoint: globalRewardCheckpoint
        });
        _slashingInstances[operator].push(instance);
        super._slashOperatorVotes(operator, remainingPercentage);
        _afterSlash(operator, remainingPercentage);
    }

    /// @dev Overrides the `delegatorStake` function in `StakeManager` to reflect correct stake for a delegator accounting for slashing
    function _delegatorStake(address delegator) internal view override returns (uint96) {
        (, uint256 remainingPercentage,,,,) = _calculateSlashing(delegator, type(uint256).max, _globalRewardCheckpoint);
        return _remainingStake(StakeManager._delegatorStake(delegator), remainingPercentage);
    }

    /// @dev Overrides the `slashableStake` function in `StakeManager` to reflect correct slashable stake for a delegator accounting for slashing
    function _slashableStake(address delegator) internal view override returns (uint96) {
        (, uint256 remainingPercentage,,,,) = _calculateSlashing(delegator, type(uint256).max, _globalRewardCheckpoint);
        return _remainingStake(StakeManager._slashableStake(delegator), remainingPercentage);
    }

    /// @dev iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.
    /// @dev In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.
    function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
        internal
        view
        returns (
            SlashingType slashingType,
            uint256 remainingPercentage,
            uint160 delegatorLength,
            uint256 newRewards,
            uint256 slashedRewards,
            uint256 newCheckpoint
        )
    {
        address operator = delegates(delegator);
        uint96 currentStake = StakeManager._delegatorStake(delegator);
        uint256 currentCheckpoint = _rewardCheckpointOf[delegator];
        remainingPercentage = PERCENTAGE_DENOMINATOR;
        // user not delegated to an operator
        if (operator == address(0)) return (SlashingType.NOT_SLASHED, remainingPercentage, 0, 0, 0, currentCheckpoint);
        DelegatorSlashingData memory slashingData = _delegatorSlashingData[delegator];
        delegatorLength = slashingData.length;
        uint256 operatorLength = _slashingInstances[operator].length;
        if (!_isDelegatorSlashed(delegatorLength, operatorLength)) {
            return (SlashingType.NOT_SLASHED, remainingPercentage, delegatorLength, 0, 0, currentCheckpoint);
        }
        slashingType = SlashingType.FULL_SLASH;
        bool isDeposited = _isDepositedIntoUniStaker(delegator);
        newCheckpoint = currentCheckpoint;
        uint256 i = 0;
        while (_isDelegatorSlashed(delegatorLength, operatorLength)) {
            if (i == n) {
                slashingType = SlashingType.PARTIAL_SLASH;
                break;
            }
            SlashingInstance memory instance = _slashingInstances[operator][delegatorLength];
            if (isDeposited) {
                newRewards += _calculateRewardFromTo(
                    _remainingStake(currentStake, remainingPercentage), newCheckpoint, instance.rewardCheckpoint
                );
                newCheckpoint = instance.rewardCheckpoint;
            }
            remainingPercentage = (remainingPercentage * instance.remainingPercentage) / PERCENTAGE_DENOMINATOR;
            delegatorLength++;
            i++;
        }
        if (isDeposited) {
            if (slashingType == SlashingType.FULL_SLASH) {
                // calculate the remaining rewards from the last slashing instance until now if all slashing instances have been applied
                newRewards += _calculateRewardFromTo(
                    _remainingStake(currentStake, remainingPercentage), newCheckpoint, globalCheckpoint
                );
                newCheckpoint = globalCheckpoint;
            }
            slashedRewards = _calculateRewardFromTo(
                slashingData.stakeBeforePartialSlashing != 0 ? slashingData.stakeBeforePartialSlashing : currentStake,
                currentCheckpoint,
                newCheckpoint
            );
            slashedRewards -= newRewards;
        }
    }

    function _isDelegatorSlashed(uint256 delegatorInstanceLength, uint256 operatorLength)
        internal
        pure
        returns (bool)
    {
        return delegatorInstanceLength < operatorLength;
    }

    function _remainingStake(uint96 stake_, uint256 remainingPercentage) internal pure returns (uint96) {
        return uint96((uint256(stake_) * remainingPercentage) / PERCENTAGE_DENOMINATOR);
    }

    /// TODO invalidation of group of slashers by using nonces?
    function SLASHER_ROLE() public pure returns (bytes32) {
        return keccak256('SLASHER_ROLE');
    }

    function _afterSlash(address operator, uint256 remainingPercentage) internal virtual {}
}
