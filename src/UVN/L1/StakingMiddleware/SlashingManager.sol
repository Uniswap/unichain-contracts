// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ISlashingManager} from '../../../interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol';
import {DelegatorAccessControl} from './DelegatorAccessControl.sol';
import {IProtocolRewardDistributor, ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';
import {IStakeManager, StakeManager} from './StakeManager.sol';

/// @title SlashingManager - Base contract for the StakingMiddleware
/// @notice This contract manages the slashing of delegators and operators. When operators are slashed, the slashed amount is converted into the remaining percentage of the operator's slashable delegated stake. The voting power of the operator is updated immediately. As delegators have their own deposits into the UniStaker contract, slashing is applied to the delegator's slashable stake when the delegator next interacts with the StakingMiddleware contract. Slashing can also be applied by anyone at any time. To ensure there isn't an incentive to not stay slashed and continue accruing protocol fees in the UniStaker contract, rewards accrued by the delegator are also slashed.
abstract contract SlashingManager is DelegatorAccessControl, ISlashingManager {
    bytes32 public constant SLASHER_ROLE = keccak256('SLASHER_ROLE');

    /// @dev Slashing instance recorded when an operator is slashed
    struct SlashingInstance {
        /// @dev The remaining percentage of the slashable stake of an operator after a slashing instance is applied
        uint96 remainingPercentage;
        /// @dev The reward checkpoint at the time of slashing to calculate slashed rewards for delegators
        uint256 rewardCheckpoint;
    }

    /// @dev Result of a slashing calculation
    struct SlashingResult {
        /// @dev The remaining percentage of the slashable stake of a delegator after applying slashing instances
        uint256 remainingPercentage;
        /// @dev The next slashing instance of a delegator, if all slashing instances have been applied, the next slashing instance will be the operator's slashing instances array length, else the delegator is still slashable
        uint256 next;
        /// @dev The new rewards of a delegator after applying slashing instances, adjusted by the slashed stake
        uint256 newRewards;
        /// @dev The slashed rewards of a delegator after applying slashing instances
        uint256 slashedRewards;
        /// @dev The new reward checkpoint of a delegator after applying slashing instances
        uint256 newCheckpoint;
    }

    /// @dev List of slashing instances for an operator
    mapping(address operator => SlashingInstance[] instances) internal _slashingInstances;
    /// @dev Points to the next slashing instance of an operator a delegator delegated to, if the next slashing instance is equal to the operator's slashing instances array length, the delegator is not slashed
    mapping(address delegator => uint256 nextSlashingInstance) internal _delegatorNextSlashingInstance;

    /// @dev After a delegator selects an operator, store the number of slashing instances an operator had before the delegation to keep track of future slashing instances that occur after the delegation
    function _afterDelegation(address delegator, address operator) internal virtual override {
        super._afterDelegation(delegator, operator);
        _delegatorNextSlashingInstance[delegator] = _slashingInstances[operator].length;
    }

    /// @dev After a delegator undelegates from an operator, reset the slashing tracking data for the delegator
    function _afterUndelegation(address delegator) internal virtual override {
        super._afterUndelegation(delegator);
        _delegatorNextSlashingInstance[delegator] = 0;
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
    function _beforeUniStakerDeposit(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerDeposit(delegator);
    }

    /// @dev Before a delegator withdraws from the UniStaker contract, apply all pending slashing instances to the delegator's stake
    function _beforeUniStakerWithdrawal(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUniStakerWithdrawal(delegator);
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
    function _beforeUndelegationAnnouncement(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUndelegationAnnouncement(delegator);
    }

    /// @dev Before a delegator undelegates from an operator, apply all pending slashing instances to the delegator's stake
    function _beforeUndelegation(address delegator) internal override {
        applySlashing(delegator, type(uint256).max);
        super._beforeUndelegation(delegator);
    }

    /// @inheritdoc ISlashingManager
    function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE) {
        if (amount == 0) revert SlashingAmountZero();
        uint96 stakeBefore = slashableOperatorStake(operator);
        if (amount > stakeBefore) amount = stakeBefore;
        uint256 remainingPercentage = ((stakeBefore - amount) * PERCENTAGE_DENOMINATOR) / stakeBefore;
        _slashOperatorVotes(operator, remainingPercentage);
    }

    /// @inheritdoc ISlashingManager
    function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE) {
        if (percentage > PERCENTAGE_DENOMINATOR) revert SlashingPercentageTooHigh();
        if (percentage == 0) revert SlashingAmountZero();
        _slashOperatorVotes(operator, PERCENTAGE_DENOMINATOR - percentage);
    }

    /// @inheritdoc ISlashingManager
    function applySlashing(address delegator, uint256 n) public {
        if (n == 0) return;
        // pull rewards and get the current reward checkpoint
        uint256 globalRewardCheckpoint = _updateGlobalRewardCheckpoint();

        SlashingResult memory result = _calculateSlashing(delegator, n, globalRewardCheckpoint);
        if (!_slashingOccurred(result)) return;

        // update the next slashing instance
        _delegatorNextSlashingInstance[delegator] = result.next;
        if (result.newRewards != 0) {
            _distributeRewards(delegator, result.newRewards, result.newCheckpoint);
        }
        if (result.slashedRewards != 0) {
            REWARD_TOKEN.transfer(slashingBeneficiary(), result.slashedRewards);
        }
        _slashDelegatorStake(delegator, result.remainingPercentage);
    }

    /// @inheritdoc ISlashingManager
    function slashingPendingForDelegator(address delegator) external view returns (bool) {
        address operator = delegates(delegator);
        if (operator == address(0)) return false;
        uint256 nextDelegatorInstance = _delegatorNextSlashingInstance[delegator];
        uint256 operatorLength = _slashingInstances[operator].length;
        return _isDelegatorSlashed(nextDelegatorInstance, operatorLength);
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
        SlashingResult memory result = _calculateSlashing(delegator, type(uint256).max, globalCheckpoint);
        if (_slashingOccurred(result)) {
            return _earnedRewardsOf[delegator] + result.newRewards;
        }
        return super.rewardsOf(delegator);
    }

    // @audit Can introduce minor rounding errors between the sum of all remaining balances and the the recorded total stake due to rounding errors
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
    function delegatorStake(address delegator) public view override(StakeManager, IStakeManager) returns (uint96) {
        SlashingResult memory result = _calculateSlashing(delegator, type(uint256).max, _globalRewardCheckpoint);
        return _remainingStake(_delegatorStake(delegator), result);
    }

    /// @dev Overrides the `slashableStake` function in `StakeManager` to reflect correct slashable stake for a delegator accounting for slashing
    function slashableStake(address delegator) public view override(StakeManager, IStakeManager) returns (uint96) {
        SlashingResult memory result = _calculateSlashing(delegator, type(uint256).max, _globalRewardCheckpoint);
        return _remainingStake(_slashableStake(delegator), result);
    }

    /// @dev iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.
    /// @dev In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.
    function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
        internal
        view
        returns (SlashingResult memory result)
    {
        address operator = _slashableOperatorOf(delegator);
        uint96 currentStake = _delegatorStake(delegator);
        result.newCheckpoint = _rewardCheckpointOf[delegator];
        result.remainingPercentage = PERCENTAGE_DENOMINATOR;
        result.next = _delegatorNextSlashingInstance[delegator];
        uint256 operatorLength = _slashingInstances[operator].length;
        if (operator == address(0) || !_isDelegatorSlashed(result.next, operatorLength)) {
            // user not delegated to an operator or not slashed
            return result;
        }
        // if the delegator has deposited their stake into the UniStaker contract, slash their rewards
        bool isDeposited = _isDepositedIntoUniStaker(delegator);
        uint256 i = 0;
        while (_isDelegatorSlashed(result.next, operatorLength)) {
            if (i == n) {
                // circuit breaker to prevent DOS vulnerabilities
                return result;
            }
            SlashingInstance memory instance = _slashingInstances[operator][result.next];
            // current stake before the slashing instance occurred, if i == 0, it's the unslashed stake, else it's the remaining stake after the previous slashing instance occurred
            uint256 stakeBefore = _remainingStake(currentStake, result);
            if (isDeposited) {
                // calculate rewards earned before the slashing instance occurred (e.g., before the delegator was slashed until the slashing instance occurred if i == 0 or from the last slashing instance until the current slashing instance if i > 0)
                result.newRewards +=
                    _calculateRewardFromTo(stakeBefore, result.newCheckpoint, instance.rewardCheckpoint);
                // update the reward checkpoint to the point of the slashing instance
                result.newCheckpoint = instance.rewardCheckpoint;
            }
            // apply the remaining percentage of the slashing instance to the remaining stake of the delegator
            result.remainingPercentage =
                (result.remainingPercentage * instance.remainingPercentage) / PERCENTAGE_DENOMINATOR;
            // mark the slashing instance as applied by incrementing to the next slashing instance
            result.next++;
            i++;
            if (isDeposited) {
                // calculate the rewards the slashed stake accrued from the moment of the slashing until now
                uint256 slashedStake = stakeBefore - _remainingStake(currentStake, result);
                result.slashedRewards += _calculateRewardFromTo(slashedStake, result.newCheckpoint, globalCheckpoint);
            }
        }
        if (isDeposited) {
            // after all slashing instances have been applied, calculate the new rewards for the remaining stake from the last slashing instance until now
            result.newRewards +=
                _calculateRewardFromTo(_remainingStake(currentStake, result), result.newCheckpoint, globalCheckpoint);
            result.newCheckpoint = globalCheckpoint;
        }
    }

    /// @dev Checks whether a delegator has pending slashing instances, if the next slashing instance is equal to the operator's slashing instances array length, the delegator is not slashed
    function _isDelegatorSlashed(uint256 nextDelegatorInstance, uint256 operatorLength) internal pure returns (bool) {
        return nextDelegatorInstance < operatorLength;
    }

    /// @dev Applies a slashing result to a stake
    function _remainingStake(uint96 stake_, SlashingResult memory result) internal pure returns (uint96) {
        return uint96((uint256(stake_) * result.remainingPercentage) / PERCENTAGE_DENOMINATOR);
    }

    /// @dev Checks a slashing result whether a slashing occurred, if the remaining percentage is not 100%, a slashing occurred
    function _slashingOccurred(SlashingResult memory result) internal pure returns (bool) {
        return result.remainingPercentage != PERCENTAGE_DENOMINATOR;
    }

    function _afterSlash(address operator, uint256 remainingPercentage) internal virtual {}
}
