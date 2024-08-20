// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IL2CrossDomainMessenger} from './interfaces/IL2CrossDomainMessenger.sol';
import {ERC20, ERC20Votes} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

/// @title L2 Stake Manager
/// @notice The L2StakeManager is a token that keeps track of the L1 stake of an attester on L2.
contract L2StakeManager is ERC20Votes {
    IL2CrossDomainMessenger internal constant MESSENGER =
        IL2CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    address internal immutable L1_STAKE_MANAGER;

    error Unauthorized();
    error TransfersDisabled();

    modifier onlyL1StakeManager() {
        if (msg.sender != address(MESSENGER) || MESSENGER.xDomainMessageSender() != L1_STAKE_MANAGER) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address l1StakeManager) ERC20('L2 Stake Manager', 'L2SM') EIP712('L2StakeManager', '1') {
        L1_STAKE_MANAGER = l1StakeManager;
    }

    function registerDeposit(address user, uint256 amount, address delegatee) external onlyL1StakeManager {
        // TODO account for delegation during reward distribution
        // normal staking on L1 => delegate management on L2

        // Do not delegate if already delegated to same address
        if (delegates(user) != delegatee) {
            // Self delegate if no delegatee is provided
            if (delegatee == address(0)) delegatee = user;
            _delegate(user, delegatee);
        }
        _mint(user, amount);
    }

    function registerWithdrawal(address user, uint256 amount) external onlyL1StakeManager {
        _burn(user, amount);
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from != address(0) && to != address(0)) revert TransfersDisabled();
        super._update(from, to, amount);
    }
}
