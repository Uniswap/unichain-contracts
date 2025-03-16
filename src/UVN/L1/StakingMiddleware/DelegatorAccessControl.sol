// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IDelegatorAccessControl,
    IDelegatorVerifier
} from '../../../interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol';
import {OperatorManager} from './OperatorManager.sol';

/// @title DelegatorAccessControl - Base contract for the StakingMiddleware
/// @notice This contract manages the access control of delegators to operators. It allows Operators to set rules for delegation. Self-delegation is always allowed. Operators can toggle whether delegation to them is allowed or not. Should an operator allow delegation, they can implement their own verification logic by two different mechanisms. Either by providing a verifier contract that implements the `IDelegatorVerifier` interface that verifies whether a delegator is allowed to delegate to them or not. Because the `delegate` function specified by ERC-5805 does not allow for arbitrary data to be passed during delegation, the operator can also provide an `authorizedSender` address. If a delegator is delegating via signature, the `authorizedSender` address can be set to ensure that the signature is provided by a contract that can perform arbitrary checks (e.g., verify a merkle proof to ensure a delegator is allowed).
abstract contract DelegatorAccessControl is IDelegatorAccessControl, OperatorManager {
    struct AccessControl {
        bool acceptDelegation;
        address authorizedSender;
        IDelegatorVerifier verifier;
    }

    mapping(address delegator => AccessControl accessControl) private _delegatorAccessControl;

    /// @dev Before a delegator selects an operator, check if they are allowed to delegate to them
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

    /// @dev Checks if a delegator is allowed to delegate to an operator
    /// @dev Self-delegation is always allowed
    /// @dev If the operator does not accept delegation, revert
    /// @dev If the delegation is via signature and the authorized sender is set, ensure that the `delegate` function is called by the authorized sender
    /// @dev If a verifier contract is set, call it to verify if the delegator is allowed to delegate to the operator
    /// @dev If the authorized sender is set, but the delegator is not delegating by signature, revert if no verifier is set, else check verifier contract
    function _allowDelegation(address delegator, address operator) internal view returns (bool) {
        AccessControl memory accessControl = _delegatorAccessControl[operator];
        if (delegator == operator) {
            // allow self-delegation by default
            return true;
        }
        if (!accessControl.acceptDelegation) {
            return false;
        }
        if (accessControl.authorizedSender != address(0)) {
            if (accessControl.authorizedSender == msg.sender) {
                // delegated by signature and authorized sender is the msg.sender, allow
                // @audit authorized sender could be set to the delegator, in this case a delegation from the delegator directly would pass
                return true;
            }
            if (delegator != msg.sender) {
                // delegating by signature and authorized sender is not the msg.sender, revert
                return false;
            }
            if (address(accessControl.verifier) == address(0)) {
                // if not delegating by signature and no verifier is set, revert, else check verifier contract
                return false;
            }
        }
        if (address(accessControl.verifier) != address(0)) {
            return accessControl.verifier.allowDelegation(delegator);
        }
        return true;
    }
}
