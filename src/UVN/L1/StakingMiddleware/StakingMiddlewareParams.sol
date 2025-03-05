// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddlewareParams} from '../../../interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

contract StakingMiddlewareParams is IStakingMiddlewareParams, AccessControl {
    bytes32 public constant PARAMS_SETTER_ROLE = keccak256('PARAMS_SETTER_ROLE');

    uint256 private _withdrawalDelay;

    constructor(address initialAdmin, uint256 withdrawalDelay_) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _setWithdrawalDelay(withdrawalDelay_);
    }

    function withdrawalDelay() public view returns (uint256) {
        return _withdrawalDelay;
    }

    function updateWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(PARAMS_SETTER_ROLE) {
        _setWithdrawalDelay(withdrawalDelay_);
    }

    function _setWithdrawalDelay(uint256 withdrawalDelay_) internal {
        uint256 oldWithdrawalDelay = _withdrawalDelay;
        _withdrawalDelay = withdrawalDelay_;
        emit WithdrawalDelayUpdated(oldWithdrawalDelay, withdrawalDelay_);
    }
}
