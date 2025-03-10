// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20, IStakeManager} from '../../../interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol';
import {StakingMiddlewareParams} from './StakingMiddlewareParams.sol';

contract StakeManager is StakingMiddlewareParams, IStakeManager {
    mapping(address delegator => uint96 stake) private _depositorStake;

    IERC20 public immutable STAKE_TOKEN;

    constructor(address stakeToken, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        StakingMiddlewareParams(initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {
        STAKE_TOKEN = IERC20(stakeToken);
    }

    /// @inheritdoc IStakeManager
    function delegatorStake(address delegator) external view returns (uint96) {
        return _delegatorStake(delegator);
    }

    /// @inheritdoc IStakeManager
    function deposit(uint96 amount) external {
        _beforeDeposit(msg.sender, amount);
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        STAKE_TOKEN.transferFrom(msg.sender, address(this), amount);
        _depositorStake[msg.sender] += amount;
        emit StakeDeposited(msg.sender, amount);
        _afterDeposit(msg.sender, amount);
    }

    /// @inheritdoc IStakeManager
    function withdraw(uint96 amount) external {
        _beforeWithdrawal(msg.sender, amount);
        uint256 currentStake = _depositorStake[msg.sender];
        if (currentStake < amount) revert InsufficientBalance();
        _depositorStake[msg.sender] -= amount;
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        STAKE_TOKEN.transfer(msg.sender, amount);
        emit StakeWithdrawn(msg.sender, amount);
        _afterWithdrawal(msg.sender, amount);
    }

    function _slashDelegatorStake(address delegator, uint96 amount) internal {
        // @audit INVARIANT: the amount slashed is always less or equal to the delegator stake after slashing
        _depositorStake[delegator] -= amount;
        STAKE_TOKEN.transfer(slashingBeneficiary(), amount);
        emit StakeSlashed(delegator, amount);
    }

    function _delegatorStake(address delegator) internal view virtual returns (uint96) {
        return _depositorStake[delegator];
    }

    function _beforeDeposit(address delegator, uint96 amount) internal virtual {}

    function _afterDeposit(address delegator, uint96 amount) internal virtual {}

    function _beforeWithdrawal(address delegator, uint96 amount) internal virtual {}

    function _afterWithdrawal(address delegator, uint96 amount) internal virtual {}
}
