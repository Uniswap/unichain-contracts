// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IDefaultDelegatorClaim,
    IDelegatorClaim,
    IOperatorFeeManager
} from '../../interfaces/UVN/L2/IDefaultDelegatorClaim.sol';
import {AddressAliasHelper} from 'lib/optimism/packages/contracts-bedrock/src/vendor/AddressAliasHelper.sol';

contract DefaultDelegatorClaim is IDefaultDelegatorClaim {
    uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
    uint256 private constant PRECISION = 1e27;
    address private immutable STAKE_TABLE;
    /// @inheritdoc IDefaultDelegatorClaim
    address public immutable OPERATOR;

    /// @inheritdoc IDefaultDelegatorClaim
    IOperatorFeeManager public operatorFeeManager;
    /// @inheritdoc IDefaultDelegatorClaim
    uint256 public totalDelegation;
    /// @inheritdoc IDefaultDelegatorClaim
    mapping(address delegator => uint256 amount) public delegationOf;

    uint256 private _globalCheckpoint;
    mapping(address delegator => uint256 checkpoint) private _checkpointOf;
    mapping(address delegator => uint256 earnedRewards) private _earnedRewardsOf;

    constructor(address operator) {
        STAKE_TABLE = msg.sender;
        OPERATOR = operator;
    }

    /// @dev Receives rewards from the reward distributor contract
    /// @dev If the operator has set an operator fee manager contract, the operator fee is calculated and handled by that contract, else no operator fee is applied
    /// @dev The remaining reward is distributed among all delegators
    receive() external payable {
        uint256 reward = msg.value;
        uint256 operatorFee;
        if (address(operatorFeeManager) != address(0)) {
            operatorFee = operatorFeeManager.operatorFee(reward);
            if (operatorFee > reward) revert OperatorFeeExceedsReward();
            reward -= operatorFee;
        }
        if (reward != 0) {
            uint256 totalDelegation_ = totalDelegation;
            if (totalDelegation_ == 0) revert NoDelegations();
            _globalCheckpoint += (reward * PRECISION) / totalDelegation_;
        }
        if (operatorFee > 0) {
            (bool success, bytes memory reason) = address(operatorFeeManager).call{value: operatorFee}('');
            if (!success) {
                revert WrappedError(
                    address(operatorFeeManager),
                    bytes4(0),
                    reason,
                    abi.encodePacked(IDefaultDelegatorClaim.EthTransferFailed.selector)
                );
            }
        }
        emit RewardDistributed(reward, operatorFee);
    }

    /// @inheritdoc IDelegatorClaim
    /// @dev When an operator is slashed, delegator stakes are only updated when slashing is applied on L1
    function reportDelegatorStake(address delegator, uint256 newDelegatorStake) external {
        if (msg.sender != STAKE_TABLE) revert NotStakeTable();
        _updateRewardCheckpoint(delegator);
        uint256 currentDelegatorStake = delegationOf[delegator];
        delegationOf[delegator] = newDelegatorStake;
        if (newDelegatorStake > currentDelegatorStake) {
            totalDelegation += (newDelegatorStake - currentDelegatorStake);
        } else if (currentDelegatorStake > newDelegatorStake) {
            totalDelegation -= (currentDelegatorStake - newDelegatorStake);
        }
        emit BalanceUpdated(delegator, newDelegatorStake);
    }

    /// @inheritdoc IDefaultDelegatorClaim
    function setOperatorFeeManager(IOperatorFeeManager operatorFeeManager_) external {
        if (msg.sender != OPERATOR) revert NotOperator();
        operatorFeeManager = operatorFeeManager_;
        emit OperatorFeeManagerSet(address(operatorFeeManager_));
    }

    /// @inheritdoc IDefaultDelegatorClaim
    function claimRewards(address delegator, address to) external {
        if (msg.sender != delegator && AddressAliasHelper.undoL1ToL2Alias(msg.sender) != delegator) {
            revert NotDelegator();
        }
        _updateRewardCheckpoint(delegator);
        uint256 rewards = _earnedRewardsOf[delegator];
        if (rewards != 0) {
            _earnedRewardsOf[delegator] = 0;
            (bool success, bytes memory reason) = to.call{value: rewards}('');
            if (!success) {
                revert WrappedError(
                    to, bytes4(0), reason, abi.encodePacked(IDefaultDelegatorClaim.EthTransferFailed.selector)
                );
            }
            emit RewardsClaimed(delegator, to, rewards);
        }
    }

    /// @inheritdoc IDefaultDelegatorClaim
    function rewardsOf(address account) external view returns (uint256) {
        return _earnedRewardsOf[account] + _calculateReward(account);
    }

    /// @dev Updates the reward checkpoint for an account and adds the reward to the earned rewards
    function _updateRewardCheckpoint(address account) internal {
        _earnedRewardsOf[account] += _calculateReward(account);
        _checkpointOf[account] = _globalCheckpoint;
    }

    /// @dev Calculates the reward for an account based on the global checkpoint and the account's checkpoint
    function _calculateReward(address account) internal view returns (uint256) {
        return (delegationOf[account] * (_globalCheckpoint - _checkpointOf[account])) / PRECISION;
    }
}
