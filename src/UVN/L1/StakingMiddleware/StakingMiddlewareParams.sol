// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IDelegationManager} from '../../../interfaces/UVN/L1/IDelegationManager.sol';
import {IStakingMiddlewareParams} from '../../../interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

contract StakingMiddlewareParams is IStakingMiddlewareParams, AccessControl {
    bytes32 public constant PARAMS_SETTER_ROLE = keccak256('PARAMS_SETTER_ROLE');

    uint256 private _withdrawalDelay;
    IDelegationManager private _delegationManager;

    constructor(address initialAdmin, uint256 withdrawalDelay_, IDelegationManager delegationManager_) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _setWithdrawalDelay(withdrawalDelay_);
        _delegationManager = delegationManager_;
    }

    function withdrawalDelay() public view returns (uint256) {
        return _withdrawalDelay;
    }

    function delegationManager() public view returns (IDelegationManager) {
        return _delegationManager;
    }

    function updateWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(PARAMS_SETTER_ROLE) {
        _setWithdrawalDelay(withdrawalDelay_);
    }

    function updateDelegationManager(IDelegationManager delegationManager_) external onlyRole(PARAMS_SETTER_ROLE) {
        _delegationManager = delegationManager_;
    }

    function _setWithdrawalDelay(uint256 withdrawalDelay_) internal {
        uint256 oldWithdrawalDelay = _withdrawalDelay;
        _withdrawalDelay = withdrawalDelay_;
        emit WithdrawalDelayUpdated(oldWithdrawalDelay, withdrawalDelay_);
    }

    function _updateDelegationManager(IDelegationManager delegationManager_) internal {
        _delegationManager = delegationManager_;
        // TODO emit event, add to interface
    }
}
