// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IDelegationManager} from '../../interfaces/UVN/L1/IDelegationManager.sol';
import {IStakingMiddleware} from '../../interfaces/UVN/L1/IStakingMiddleware.sol';
import {IUniStaker} from '../../interfaces/UVN/L1/IUnistaker.sol';
import {DepositorData, StakingMiddlewareParams} from './StakingMiddleware/OperatorManager.sol';
import {SlashingManager} from './StakingMiddleware/SlashingManager.sol';
import {UniStakerWrapper} from './StakingMiddleware/UniStakerWrapper.sol';
// TODO add multicall?

contract StakingMiddleware is SlashingManager, IStakingMiddleware {
    uint96 public totalStake;

    constructor(
        address initialAdmin,
        IUniStaker unistaker_,
        uint256 withdrawalDelay_,
        address slashingBeneficiary_,
        IDelegationManager delegationManager_
    )
        UniStakerWrapper(unistaker_)
        StakingMiddlewareParams(initialAdmin, withdrawalDelay_, slashingBeneficiary_, delegationManager_)
    {}

    function updateGovernanceDelegatee(address newGovernanceDelegatee) external {
        _depositIntoUniStaker(0, newGovernanceDelegatee);
    }

    function deposit(uint96 amount) external {
        applySlashing(msg.sender, type(uint256).max);
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        stakeToken.transferFrom(msg.sender, address(this), amount);
        DepositorData storage data = _depositorData[msg.sender];
        data.stake += amount;
        totalStake += amount;
        if (_isDepositedIntoUniStaker(msg.sender)) {
            _updateRewardCheckpoint(msg.sender);
            _depositIntoUniStaker(amount, address(0));
        }
        if (data.selectedOperator != address(0)) {
            _operatorTotalStake[data.selectedOperator] += amount;
            delegationManager().mint(msg.sender, amount);
        }
    }

    // TODO withdrawal delay
    function withdraw(uint96 amount) external {
        applySlashing(msg.sender, type(uint256).max);
        DepositorData storage data = _depositorData[msg.sender];
        data.stake -= amount;
        totalStake -= amount;
        if (_isDepositedIntoUniStaker(msg.sender)) {
            _updateRewardCheckpoint(msg.sender);
            _withdrawFromUniStaker(amount);
        }
        if (data.selectedOperator != address(0)) {
            _operatorTotalStake[data.selectedOperator] -= amount;
            delegationManager().burn(msg.sender, amount);
        }
        // @audit safe ERC20 transfers do not need to be used here, as the UNI token is safe to transfer
        stakeToken.transfer(msg.sender, amount);
    }

    function depositIntoUniStaker(address governanceDelegatee) external {
        if (_isDepositedIntoUniStaker(msg.sender)) revert AlreadyDepositedIntoUniStaker();
        applySlashing(msg.sender, type(uint256).max);
        _updateRewardCheckpoint(msg.sender);
        _depositIntoUniStaker(_depositorData[msg.sender].stake, governanceDelegatee);
    }

    function withdrawFromUniStaker() external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        applySlashing(msg.sender, type(uint256).max);
        _updateRewardCheckpoint(msg.sender);
        _withdrawFromUniStaker(_depositorData[msg.sender].stake);
    }

    function alterGovernanceDelegatee(address newGovernanceDelegatee) external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        applySlashing(msg.sender, type(uint256).max);
        _depositIntoUniStaker(0, newGovernanceDelegatee);
    }

    function deselectOperator() public override {
        applySlashing(msg.sender, type(uint256).max);
        super.deselectOperator();
    }
}
