// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Votes} from '@openzeppelin/contracts/governance/utils/Votes.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {Checkpoints} from '@openzeppelin/contracts/utils/structs/Checkpoints.sol';
import {console2} from 'forge-std/console2.sol';

/// @title UniVotes
/// @notice This contract tracks voting units, balance, and validator activity for L2 accounts
/// @dev implementation uses OpenZeppelin's ERC20Votes.sol and adds additional balance checkpointing
abstract contract UniVotes is ERC20, Votes {
    using Checkpoints for Checkpoints.Trace208;

    /// @notice mapping of account to balance checkpoints
    mapping(address account => Checkpoints.Trace208 balance) private _balanceCheckpoints;

    struct AccountValidator {
        uint256 head;
        uint256 tail;
        mapping(uint256 blockNumber => uint256) next;
    }

    /// @notice linked list of account to validator
    mapping(address user => AccountValidator) private _accountValidators;

    /**
     * @dev Total supply cap has been exceeded, introducing a risk of votes overflowing.
     */
    error ERC20ExceededSafeSupply(uint256 increasedSupply, uint256 cap);

    error CannotChangeDelegation();

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getBalances(address account) public view virtual returns (uint256) {
        return _balanceCheckpoints[account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past.
     */
    function getPastBalances(address account, uint256 timepoint) public view virtual returns (uint256) {
        uint48 currentTimepoint = clock();
        if (timepoint >= currentTimepoint) {
            revert ERC5805FutureLookup(timepoint, currentTimepoint);
        }
        return _balanceCheckpoints[account].upperLookupRecent(SafeCast.toUint48(timepoint));
    }

    /**
     * @dev Checkpoint balances when transferring tokens
     */
    function _checkpointBalances(address from, address to, uint208 amount) internal {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                // if from has insufficient balance here it will revert, but not nicely with ERC20InsufficientBalance
                // as handled in the ERC20 contract
                _balanceCheckpoints[from].push(clock(), _balanceCheckpoints[from].latest() - amount);
            }
            if (to != address(0)) {
                _balanceCheckpoints[to].push(clock(), _balanceCheckpoints[to].latest() + amount);
            }
        }
    }

    function _delegate(address account, address delegatee) internal override {
        // prevent re-delegation in the same epoch
        (bool exists, uint48 key,) = _balanceCheckpoints[account].latestCheckpoint();
        if (exists && delegates(account) != delegatee) {
            uint256 lastEpochBlock = getLastEpochBlock();
            if (key >= lastEpochBlock && key < lastEpochBlock + EPOCH_BLOCKS()) {
                revert CannotChangeDelegation();
            }
        }
        _accountValidators[account].next[_accountValidators[account].tail] = _encodeNextValidator(delegatee, clock());
        _accountValidators[account].tail = clock();
        super._delegate(account, delegatee);
    }

    function _encodeNextValidator(address validator, uint256 blockNumber) private pure returns (uint256) {
        return (blockNumber << 160) | uint160(validator);
    }

    function _decodeNextValidator(uint256 next) private pure returns (address, uint256) {
        return (address(uint160(next)), next >> 160);
    }

    // Find the most recent validator for an account at a given block number
    // - if no validator is found, return address(0)
    function findValidator(address account, uint256 blockNumber) public view returns (address) {
        uint256 current = _accountValidators[account].head;
        address lastValidator = address(0);
        while (current <= blockNumber) {
            (address validator, uint256 next) = _decodeNextValidator(_accountValidators[account].next[current]);
            if(next == 0) break;
            lastValidator = validator;
            current = next;
        }

        return lastValidator;
    }

    function EPOCH_BLOCKS() public view virtual returns (uint256);
    function getLastEpochBlock() public view virtual returns (uint256);

    /**
     * @dev Maximum token supply. Defaults to `type(uint208).max` (2^208^ - 1).
     *
     * This maximum is enforced in {_update}. It limits the total supply of the token, which is otherwise a uint256,
     * so that checkpoints can be stored in the Trace208 structure used by {{Votes}}. Increasing this value will not
     * remove the underlying limitation, and will cause {_update} to fail because of a math overflow in
     * {_transferVotingUnits}. An override could be used to further restrict the total supply (to a lower value) if
     * additional logic requires it. When resolving override conflicts on this function, the minimum should be
     * returned.
     */
    function _maxSupply() internal view virtual returns (uint256) {
        return type(uint208).max;
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        _checkpointBalances(from, to, uint208(value)); // safe to cast here because of maxSupply check below
        super._update(from, to, value);
        if (from == address(0)) {
            uint256 supply = totalSupply();
            uint256 cap = _maxSupply();
            if (supply > cap) {
                revert ERC20ExceededSafeSupply(supply, cap);
            }
        }
        _transferVotingUnits(from, to, value);
    }

    /**
     * @dev Returns the voting units of an `account`.
     *
     * WARNING: Overriding this function may compromise the internal vote accounting.
     * `ERC20Votes` assumes tokens map to voting units 1:1 and this is not easy to change.
     */
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return _numCheckpoints(account);
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoints.Checkpoint208 memory) {
        return _checkpoints(account, pos);
    }
}
