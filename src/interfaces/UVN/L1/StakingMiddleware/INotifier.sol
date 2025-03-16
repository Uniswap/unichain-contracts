// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISlashingManager} from './ISlashingManager.sol';

/// @title Notifier - Base contract for the Notifier
/// @notice This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.
interface INotifier is ISlashingManager {
    /// @notice Emitted when the URI for a token is updated
    event URIUpdated(address indexed operator, uint256 indexed tokenId, string uri);

    /// @notice Thrown when a token is already minted
    error AlreadyMinted();
    /// @notice thrown when the `transferFrom` function is called
    error UnsafeTransfer();
    /// @notice thrown when the recipient of a safe transfer is not the operator or a contract
    error InvalidRecipient();

    /// @notice Allows an operator to mint a new token to deposit into service contracts
    function mint() external;

    /// @notice Allows an operator to set the URI for their token
    function setURI(string memory uri) external;
}
