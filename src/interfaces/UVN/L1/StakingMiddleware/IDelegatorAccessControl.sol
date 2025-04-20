// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDelegatorVerifier} from './IDelegatorVerifier.sol';
import {IOperatorManager} from './IOperatorManager.sol';

/// @title DelegatorAccessControl - Base contract for the StakingMiddleware
/// @notice This contract manages the access control of delegators to operators. It allows Operators to set rules for delegation. Self-delegation is always allowed. Operators can toggle whether delegation to them is allowed or not. Should an operator allow delegation, they can implement their own verification logic by two different mechanisms. Either by providing a verifier contract that implements the `IDelegatorVerifier` interface that verifies whether a delegator is allowed to delegate to them or not. Because the `delegate` function specified by ERC-5805 does not allow for arbitrary data to be passed during delegation, the operator can also provide an `authorizedSender` address. If a delegator is delegating via signature, the `authorizedSender` address can be set to ensure that the signature is provided by a contract that can perform arbitrary checks (e.g., verify a merkle proof to ensure a delegator is allowed).
interface IDelegatorAccessControl is IOperatorManager {
    /// @notice Emitted when the delegation status is set
    event DelegationStatusUpdated(address indexed operator, bool status);

    /// @notice Emitted when the delegation verifier is set
    event DelegationVerifierUpdated(address indexed operator, IDelegatorVerifier verifier);

    /// @notice Emitted when the authorized sender is set
    event AuthorizedSenderUpdated(address indexed operator, address sender);

    /// @notice Thrown when a delegator attempts to delegate to an operator while not meeting criteria set by the operator
    error DelegationDisallowed();

    /// @notice Enables or disables delegation to the operator
    /// @param status The new delegation status
    /// @dev When enabled, it starts enforcing the delegation verifier and authorized sender
    function setDelegationStatus(bool status) external;

    /// @notice Sets a delegation verifier contract
    /// @param verifier The address of the delegation verifier contract
    /// @dev when delegating by signature and an authorized sender is not set, the verifier delegation verifier is enforced
    function setDelegationVerifier(IDelegatorVerifier verifier) external;

    /// @notice Sets the authorized sender
    /// @param sender The address of the authorized sender
    function setAuthorizedSender(address sender) external;

    /// @notice Returns the delegation status
    function delegationStatus(address operator) external view returns (bool);

    /// @notice Returns the delegation verifier
    function delegationVerifier(address operator) external view returns (IDelegatorVerifier);

    /// @notice Returns the authorized sender
    function authorizedSender(address operator) external view returns (address);
}
