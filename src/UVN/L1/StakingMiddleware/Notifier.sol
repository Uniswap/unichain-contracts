// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INotifier} from '../../../interfaces/UVN/L1/StakingMiddleware/INotifier.sol';
import {IService} from '../../../interfaces/UVN/L1/StakingMiddleware/IService.sol';
import {OperatorManager} from './OperatorManager.sol';
import {SlashingManager} from './SlashingManager.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

/// @title Notifier - Base contract for the Notifier
/// @notice This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.
abstract contract Notifier is SlashingManager, ERC721, INotifier {
    uint256 private constant MIN_GAS = 500_000;

    mapping(address operator => string uri) private _uris;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) OperatorManager(name_) {}

    function _afterStake(address delegator, uint96 amount) internal virtual override {
        super._afterStake(delegator, amount);
        _reportOperatorStakeUpdate(delegator, true);
    }

    function _afterUnstake(address delegator, uint96 amount) internal virtual override {
        super._afterUnstake(delegator, amount);
        _reportOperatorStakeUpdate(delegator, true);
    }

    function _afterOperatorSelection(address delegator, address operator) internal virtual override {
        super._afterOperatorSelection(delegator, operator);
        _reportOperatorStakeUpdate(delegator, true);
    }

    function _afterOperatorUndelegationAnnouncement(address delegator) internal virtual override {
        super._afterOperatorUndelegationAnnouncement(delegator);
        _reportOperatorStakeUpdate(delegator, false);
    }

    function _afterSlash(address operator, uint256 remainingPercentage) internal virtual override {
        super._afterSlash(operator, remainingPercentage);
        _reportOperatorSlash(operator, remainingPercentage);
    }

    /// @inheritdoc INotifier
    function mint() external {
        uint256 tokenId = _toTokenId(msg.sender);
        if (_ownerOf(tokenId) != address(0)) revert AlreadyMinted();
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
        if (to != _toAddress(tokenId) && !_isServiceContract(to)) revert InvalidRecipient();
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev reports the new operator stake to the service contract, triggered by a balance change through a delegator action
    /// @dev if requireSuccess is true, the function will revert if the call to the service contract fails
    /// @dev if requireSuccess is false, the function will not revert if the call to the service contract fails, this ensures that a delegator cannot be bricked by a malicious operator, they should always be able to undelegate from the operator to withdraw their stake. To ensure an honest undelegation can be processed by the recipient of the call, a minimum amount of gas is enforced.
    function _reportOperatorStakeUpdate(address delegator, bool requireSuccess) internal {
        address operator = delegates(delegator);
        if (operator == address(0)) return;
        // this reverts if the operator token is not minted
        address operatorHolder = _requireOwned(_toTokenId(operator));
        if (operatorHolder != operator) {
            uint256 minGas = requireSuccess ? gasleft() * 63 / 64 : MIN_GAS;
            try IService(operatorHolder).reportOperatorStake{gas: minGas}(
                operator, uint96(getVotes(operator)), delegator, _delegatorStake(delegator)
            ) {} catch (bytes memory reason) {
                if (!requireSuccess) return;
                revert WrappedError(
                    operatorHolder,
                    IService.reportOperatorStake.selector,
                    reason,
                    abi.encodePacked(INotifier.NotificationFailed.selector)
                );
            }
        }
    }

    function _reportOperatorSlash(address operator, uint256 remainingPercentage) internal {
        address operatorHolder = _ownerOf(_toTokenId(operator));
        if (operator != address(0) && operatorHolder != address(0) && operatorHolder != operator) {
            try IService(operatorHolder).reportOperatorSlash{gas: MIN_GAS}(operator, remainingPercentage) {} catch {}
        }
    }

    function _isServiceContract(address account) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        // take into account 7702 accounts
        if (size == 0 || size == 23) return false;
        return IService(account).supportsInterface(type(IService).interfaceId);
    }

    function _toTokenId(address owner) private pure returns (uint256) {
        return uint256(uint160(owner));
    }

    function _toAddress(uint256 tokenId) private pure returns (address) {
        return address(uint160(tokenId));
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {}
}
