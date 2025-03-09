// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {OperatorManager} from './OperatorManager.sol';
import {ProtocolRewardDistributor} from './ProtocolRewardDistributor.sol';

abstract contract SlashingManager is ProtocolRewardDistributor, OperatorManager {
    uint96 private constant PERCENTAGE_DENOMINATOR = 1e18;

    struct SlashingInstance {
        uint96 remainingPercentage;
        uint256 rewardCheckpoint;
    }

    mapping(address operator => SlashingInstance[] instances) internal _slashingInstances;
    mapping(address delegator => uint256 instanceLength) internal _delegatorInstanceLengths;

    function selectOperator(address operator) public override {
        super.selectOperator(operator);
        _delegatorInstanceLengths[msg.sender] = _slashingInstances[operator].length;
    }

    function deselectOperator() public virtual override {
        super.deselectOperator();
        _delegatorInstanceLengths[msg.sender] = 0;
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
        (
            uint96 newStake,
            uint256 delegatorInstanceLength,
            uint256 newRewards,
            uint256 slashedRewards,
            uint256 newCheckpoint
        ) = _calculateSlashing(delegator, n, globalRewardCheckpoint);
        _delegatorInstanceLengths[delegator] = delegatorInstanceLength;
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
        uint256 delegatorInstanceLength = _delegatorInstanceLengths[delegator];
        uint256 operatorLength = _slashingInstances[operator].length;
        return _isDelegatorSlashed(delegatorInstanceLength, operatorLength);
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
        SlashingInstance memory instance =
            SlashingInstance({remainingPercentage: remainingPercentage, rewardCheckpoint: globalRewardCheckpoint});
        _slashingInstances[operator].push(instance);
        // TODO notify delegation manager about slashing event
    }

    /// @dev iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.
    /// @dev In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.
    function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
        internal
        view
        returns (
            uint96 newStake,
            uint256 delegatorLength,
            uint256 newRewards,
            uint256 slashedRewards,
            uint256 newCheckpoint
        )
    {
        address operator = _operator(delegator);
        newStake = super.delegatorStake(delegator);
        newCheckpoint = _rewardCheckpointOf[delegator];
        // user not delegated to an operator
        if (operator == address(0)) return (newStake, 0, 0, 0, newCheckpoint);
        delegatorLength = _delegatorInstanceLengths[delegator];
        uint256 operatorLength = _slashingInstances[operator].length;
        if (!_isDelegatorSlashed(delegatorLength, operatorLength)) {
            return (newStake, delegatorLength, 0, 0, newCheckpoint);
        }
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

    function SLASHER_ROLE() public view returns (bytes32) {
        return keccak256(abi.encodePacked('SLASHER_ROLE', delegationManager()));
    }
}
