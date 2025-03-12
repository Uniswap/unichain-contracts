// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IDelegatorAccessControl,
    IDelegatorVerifier
} from '../../../interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol';
import {OperatorManager} from './OperatorManager.sol';

abstract contract DelegatorAccessControl is IDelegatorAccessControl, OperatorManager {
    struct AccessControl {
        bool acceptDelegation;
        address authorizedSender;
        IDelegatorVerifier verifier;
    }

    mapping(address delegator => AccessControl accessControl) private _delegatorAccessControl;

    function _beforeOperatorSelection(address delegator, address operator) internal override {
        if (!_allowDelegation(delegator, operator)) revert DelegationDisallowed();
        super._beforeOperatorSelection(delegator, operator);
    }

    /// @inheritdoc IDelegatorAccessControl
    function setDelegationStatus(bool status) external {
        _delegatorAccessControl[msg.sender].acceptDelegation = status;
        emit DelegationStatusUpdated(msg.sender, status);
    }

    /// @inheritdoc IDelegatorAccessControl
    function setDelegationVerifier(IDelegatorVerifier verifier) external {
        _delegatorAccessControl[msg.sender].verifier = verifier;
        emit DelegationVerifierUpdated(msg.sender, verifier);
    }

    /// @inheritdoc IDelegatorAccessControl
    function setAuthorizedSender(address sender) external {
        _delegatorAccessControl[msg.sender].authorizedSender = sender;
        emit AuthorizedSenderUpdated(msg.sender, sender);
    }

    /// @inheritdoc IDelegatorAccessControl
    function delegationStatus(address operator) external view returns (bool) {
        return _delegatorAccessControl[operator].acceptDelegation;
    }

    /// @inheritdoc IDelegatorAccessControl
    function delegationVerifier(address operator) external view returns (IDelegatorVerifier) {
        return _delegatorAccessControl[operator].verifier;
    }

    /// @inheritdoc IDelegatorAccessControl
    function authorizedSender(address operator) external view returns (address) {
        return _delegatorAccessControl[operator].authorizedSender;
    }

    function _allowDelegation(address delegator, address operator) internal view returns (bool) {
        AccessControl memory accessControl = _delegatorAccessControl[operator];
        if (delegator == operator) {
            // allow self-delegation by default
            return true;
        }
        if (!accessControl.acceptDelegation) {
            return false;
        }
        if (delegator != msg.sender) {
            // delegating by signature
            if (accessControl.authorizedSender != address(0) && accessControl.authorizedSender != msg.sender) {
                return false;
            }
        }
        if (address(accessControl.verifier) != address(0) && accessControl.authorizedSender == address(0)) {
            return accessControl.verifier.allowDelegation(delegator);
        }
        return true;
    }
}
