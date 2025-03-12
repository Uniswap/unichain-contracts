// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IDelegatorVerifier} from './IDelegatorVerifier.sol';
import {IOperatorManager} from './IOperatorManager.sol';

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
    /// @dev when delegating by signature and the authorized sender is set, the verifier contract is not called, as the delegation already passed an authorization check
    function setAuthorizedSender(address sender) external;

    /// @notice Returns the delegation status
    function delegationStatus(address operator) external view returns (bool);

    /// @notice Returns the delegation verifier
    function delegationVerifier(address operator) external view returns (IDelegatorVerifier);

    /// @notice Returns the authorized sender
    function authorizedSender(address operator) external view returns (address);
}
