// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INotifier} from '../../../interfaces/UVN/L1/StakingMiddleware/INotifier.sol';

import {OperatorManager} from './OperatorManager.sol';
import {SlashingManager} from './SlashingManager.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

/// @title Notifier - Base contract for the Notifier
/// @notice This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.
abstract contract Notifier is SlashingManager, ERC721, INotifier {
    mapping(address operator => string uri) private _uris;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) OperatorManager(name_) {}

    /// @inheritdoc INotifier
    function mint() external {
        uint256 tokenId = _toTokenId(msg.sender);
        if (ownerOf(tokenId) != address(0)) revert AlreadyMinted();
        _mint(msg.sender, tokenId);
    }

    /// @inheritdoc INotifier
    function setURI(string memory uri) external {
        uint256 tokenId = _toTokenId(msg.sender);
        _requireOwned(tokenId);
        _uris[msg.sender] = uri;
        emit URIUpdated(msg.sender, tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return _uris[_toAddress(tokenId)];
    }

    /// @dev disallow unsafe transfers
    function transferFrom(address, address, uint256) public pure override {
        revert UnsafeTransfer();
    }

    /// @dev only allow transfers to contracts and the operator
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (to != _toAddress(tokenId) && !_isContract(to)) revert InvalidRecipient();
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _isContract(address account) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        // take into account 7702 accounts
        return size != 0 && size != 23;
    }

    function _toTokenId(address owner) private pure returns (uint256) {
        return uint256(uint160(owner));
    }

    function _toAddress(uint256 tokenId) private pure returns (address) {
        return address(uint160(tokenId));
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {}
}
