// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IL2CrossDomainMessenger} from './interfaces/IL2CrossDomainMessenger.sol';

import {UniVotes} from './lib/UniVotes.sol';
import {ERC20, ERC20Votes} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

/// @title L2 Stake Manager
/// @notice The L2StakeManager is a token that keeps track of the L1 stake of an attester on L2.
contract L2StakeManager is UniVotes {
    IL2CrossDomainMessenger internal constant MESSENGER =
        IL2CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    address internal immutable L1_STAKE_MANAGER;

    error Unauthorized();
    error TransfersDisabled();
    error EpochUpdateNotAllowed();

    uint256 lastEpochBlock;

    struct Validator {
        uint256 fee;
    }

    mapping(address => Validator) public validators;

    modifier onlyL1StakeManager() {
        if (msg.sender != address(MESSENGER) || MESSENGER.xDomainMessageSender() != L1_STAKE_MANAGER) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address l1StakeManager) ERC20('L2 Stake Manager', 'L2SM') EIP712('L2StakeManager', '1') {
        L1_STAKE_MANAGER = l1StakeManager;
        lastEpochBlock = block.number;
    }

    /// @notice Register a deposit on L1, mint tokens on L2 and optionally delegate all tokens to a delegatee
    function registerDeposit(address user, uint256 amount, address delegatee) external onlyL1StakeManager {
        // Do not delegate if already delegated to same address
        if (delegates(user) != delegatee) {
            // Self delegate if no delegatee is provided
            if (delegatee == address(0)) delegatee = user;
            _delegate(user, delegatee);
        }
        _mint(user, amount);
    }

    /// @notice Register a withdrawal on L1, burn tokens on L2
    function registerWithdrawal(address user, uint256 amount) external onlyL1StakeManager {
        _burn(user, amount);
    }

    /// @notice Register a validator with a fee
    function registerValidator(address validator, uint256 fee) external onlyL1StakeManager {
        validators[validator].fee = fee;
    }

    /// @notice Return the number of blocks in an epoch
    /// at 1 block/s this is roughly 1 week
    function EPOCH_BLOCKS() public view override returns (uint256) {
        return 604_800;
    }

    /// @notice Return the start block of the current epoch
    function getLastEpochBlock() public view override returns (uint256) {
        return lastEpochBlock;
    }

    /// @notice Update the epoch after the current epoch has ended
    function updateEpoch() external {
        if (block.number < lastEpochBlock + EPOCH_BLOCKS()) {
            revert EpochUpdateNotAllowed();
        }
        lastEpochBlock = block.number;
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from != address(0) && to != address(0)) revert TransfersDisabled();
        super._update(from, to, amount);
    }
}
