// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseService} from '../../../interfaces/UVN/IBaseService.sol';
import {IService} from '../../../interfaces/UVN/L1/IService.sol';
import {INotifier} from '../../../interfaces/UVN/L1/StakingMiddleware/INotifier.sol';
import {OperatorManager} from './OperatorManager.sol';
import {SlashingManager} from './SlashingManager.sol';
import {OperatorTokenLib} from './libraries/OperatorTokenLib.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Utils} from '@openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol';

/// @title Notifier - Base contract for the Notifier
/// @notice This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.
abstract contract Notifier is SlashingManager, ERC721, INotifier {
    /// @inheritdoc INotifier
    bytes32 public constant TRUSTED_SERVICE_ROLE = keccak256('TRUSTED_SERVICE_ROLE');

    uint256 private constant MIN_GAS = 500_000;
    uint256 private constant SERVICE_CHECK_GAS = 10_000;

    mapping(address operator => string uri) private _uris;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) OperatorManager(name_) {}

    /// @dev Report the new operator stake after staking
    /// @dev Failing call to service contract can prevent a delegator from staking
    function _afterStake(address delegator, uint96 amount) internal virtual override {
        super._afterStake(delegator, amount);
        address operator = delegates(delegator);
        if (operator == address(0)) return;
        uint96 operatorStake = uint96(getVotes(operator));
        uint96 delegatorStake_ = _delegatorStake(delegator);
        _reportOperatorStakeUpdate(operator, operatorStake, delegator, delegatorStake_, true);
    }

    /// @dev Report the new operator stake after unstaking
    /// @dev Failing call to service contract can prevent a delegator from unstaking
    /// @dev Should a malicious service contract prevent unstaking, the delegator can always undelegate from the operator first
    function _afterUnstake(address delegator, uint96 amount) internal virtual override {
        super._afterUnstake(delegator, amount);
        address operator = delegates(delegator);
        if (operator == address(0)) return;
        uint96 operatorStake = uint96(getVotes(operator));
        uint96 delegatorStake_ = _delegatorStake(delegator);
        _reportOperatorStakeUpdate(operator, operatorStake, delegator, delegatorStake_, true);
    }

    /// @dev Report the new operator stake after delegation
    /// @dev Failing call to service contract can prevent a delegator from delegating to an operator
    function _afterDelegation(address delegator, address operator) internal virtual override {
        super._afterDelegation(delegator, operator);
        uint96 operatorStake = uint96(getVotes(operator));
        uint96 delegatorStake_ = _delegatorStake(delegator);
        _reportOperatorStakeUpdate(operator, operatorStake, delegator, delegatorStake_, true);
    }

    /// @dev Report the new operator stake after undelegation announcement
    /// @dev Set delegator stake to 0 as the delegator is undelegating their entire stake
    /// @dev Call to service contract is not required to prevent a DOS attack on delegators
    function _afterUndelegationAnnouncement(address delegator) internal virtual override {
        super._afterUndelegationAnnouncement(delegator);
        address operator = _slashableOperatorOf(delegator);
        uint96 operatorStake = uint96(getVotes(operator));
        uint96 delegatorStake_ = 0;
        _reportOperatorStakeUpdate(operator, operatorStake, delegator, delegatorStake_, false);
    }

    /// @dev Report the operator slash to the service contract
    /// @dev Ensures the service contract cannot prevent the operator from being slashed by reverting the call
    function _afterSlash(address operator, uint256 remainingPercentage) internal virtual override {
        super._afterSlash(operator, remainingPercentage);
        _reportOperatorSlash(operator, remainingPercentage);
    }

    /// @dev After slashing is applied, report the new delegator stake to the service contract
    function _afterDelegatorSlash(address delegator) internal virtual override {
        super._afterDelegatorSlash(delegator);
        address operator = _slashableOperatorOf(delegator);
        uint96 operatorStake = uint96(getVotes(operator));
        uint96 delegatorStake_ = _delegatorStake(delegator);
        _reportOperatorStakeUpdate(operator, operatorStake, delegator, delegatorStake_, false);
    }

    /// @inheritdoc INotifier
    function mint() external {
        uint256 tokenId = OperatorTokenLib.toTokenId(msg.sender);
        if (_ownerOf(tokenId) != address(0)) revert AlreadyMinted();
        _mint(msg.sender, tokenId);
    }

    /// @inheritdoc INotifier
    function setURI(string calldata uri) external {
        uint256 tokenId = OperatorTokenLib.toTokenId(msg.sender);
        _requireOwned(tokenId);
        _uris[msg.sender] = uri;
        emit URIUpdated(msg.sender, tokenId, uri);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return _uris[OperatorTokenLib.toAddress(tokenId)];
    }

    /// @dev disallow unsafe transfers
    function transferFrom(address, address, uint256) public pure override {
        revert UnsafeTransfer();
    }

    /// @dev Only allow transfers to service contracts and the operator
    /// @dev Notify service contracts of withdrawals
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        address operator = OperatorTokenLib.toAddress(tokenId);
        if (to != operator && !_isServiceContract(to)) revert InvalidRecipient();
        if (from != operator && _isServiceContract(from)) {
            // if current owner is a service contract, try catch the `onWithdrawal` hook to ensure the owner can always force transfer their own token but allow a service contract to implement arbitrary logic on withdrawals
            try IService(from).onWithdrawal{gas: MIN_GAS}(operator) {} catch {}
        }
        ERC721.transferFrom(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }

    /// @dev Reports the new operator stake to the service contract, triggered by a balance change through a delegator action
    /// @dev If requireSuccess is true, the function will revert if the call to the service contract fails
    /// @dev If requireSuccess is false, the function will not revert if the call to the service contract fails, this ensures that a delegator cannot be DOSed by a malicious operator, they should always be able to undelegate from the operator to withdraw their stake. To ensure an honest undelegation can be processed by the recipient of the call, a minimum amount of gas is enforced.
    function _reportOperatorStakeUpdate(
        address operator,
        uint96 operatorStake,
        address delegator,
        uint96 delegatorStake_,
        bool requireSuccess
    ) internal {
        // this reverts if the operator token is not minted
        address operatorHolder = _requireOwned(OperatorTokenLib.toTokenId(operator));
        if (operatorHolder == operator) return;
        if (!requireSuccess) {
            // if the operator is trusted, the call is allowed to always revert on failure
            requireSuccess = hasRole(TRUSTED_SERVICE_ROLE, operatorHolder);
        }
        uint256 minGas = requireSuccess ? gasleft() * 63 / 64 : MIN_GAS;
        try IService(operatorHolder).reportOperatorStake{gas: minGas}(
            operator, operatorStake, delegator, delegatorStake_
        ) {} catch (bytes memory reason) {
            if (!requireSuccess) return;
            revert WrappedError(
                operatorHolder,
                IBaseService.reportOperatorStake.selector,
                reason,
                abi.encodePacked(INotifier.NotificationFailed.selector)
            );
        }
    }

    /// @dev Reports the operator slash to the service contract
    /// @dev Ensures the service contract cannot prevent the operator from being slashed by reverting the call
    function _reportOperatorSlash(address operator, uint256 remainingPercentage) internal {
        address operatorHolder = _requireOwned(OperatorTokenLib.toTokenId(operator));
        if (operatorHolder == operator) return;
        // if the operator is trusted, the call is allowed to always revert on failure
        bool requireSuccess = hasRole(TRUSTED_SERVICE_ROLE, operatorHolder);
        uint256 minGas = requireSuccess ? gasleft() * 63 / 64 : MIN_GAS;
        try IService(operatorHolder).reportOperatorSlash{gas: minGas}(operator, remainingPercentage) {}
        catch (bytes memory reason) {
            if (!requireSuccess) return;
            revert WrappedError(
                operatorHolder,
                IBaseService.reportOperatorSlash.selector,
                reason,
                abi.encodePacked(INotifier.NotificationFailed.selector)
            );
        }
    }

    /// @dev Allow the operator to always force transfer their own token
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view override returns (bool) {
        if (spender == OperatorTokenLib.toAddress(tokenId)) return true;
        return ERC721._isAuthorized(owner, spender, tokenId);
    }

    /// @dev Checks if an account is a service contract by ensuring that the account is not an EOA or 7702 enabled account and that the smart contract supports the `IService` interface
    /// @dev Prevents malicious service contracts from preventing force transfers by reverting the ERC-165 check
    function _isServiceContract(address account) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        // take into account 7702 accounts
        if (size == 0) return false;
        if (size == 23) {
            bytes memory code = account.code;
            if (bytes2(code) == bytes2(uint16(0xef01))) return false;
        }
        try IService(account).supportsInterface{gas: SERVICE_CHECK_GAS}(type(IService).interfaceId) returns (
            bool result
        ) {
            return result;
        } catch {
            return false;
        }
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
