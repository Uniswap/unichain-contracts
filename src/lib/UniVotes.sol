// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Votes} from '@openzeppelin/contracts/governance/utils/Votes.sol';
import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";

/// @title UniVotes
/// @notice This contract tracks voting units, balance, and validator activity for L2 accounts
/// @dev implementation uses OpenZeppelin's ERC20Votes.sol and adds additional balance checkpointing
abstract contract UniVotes is ERC20, Votes {
    struct BalanceCheckpoint {
        uint48 blockNumber;
        uint256 balance;
    }

    /// @notice mapping of account to balance checkpoints
    mapping(address => BalanceCheckpoint[]) private _balances;
    
    /**
     * @dev Total supply cap has been exceeded, introducing a risk of votes overflowing.
    */
    error ERC20ExceededSafeSupply(uint256 increasedSupply, uint256 cap);

    /**
     * @dev Get the checkpointed balance of an account at a specific block number. Returns the most recent checkpoint greater than or equal to blockNumber
     */
    function getPastBalance(address account, uint256 blockNumber) public view returns (uint256) {
        BalanceCheckpoint[] memory balanceCheckpoints = _balances[account];
        uint256 length = balanceCheckpoints.length;
        uint256 mid = length / 2;
        uint256 low = 0;
        uint256 high = length - 1;
        while (low < high) {
            mid = (low + high) / 2;
            if (balanceCheckpoints[mid].blockNumber == blockNumber) {
                return balanceCheckpoints[mid].balance;
            } else if (balanceCheckpoints[mid].blockNumber < blockNumber) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        // At this point, low should be equal to high
        if (balanceCheckpoints[high].blockNumber > blockNumber) {
            return balanceCheckpoints[high].balance;
        } else {
            // Fallback to mid or handle the case where no element is greater
            return balanceCheckpoints[mid].balance;
        }
    }

    /**
     * @dev Checkpoint balances when transferring tokens
     */
    function _checkpointBalances(address from, address to, uint256 amount) internal {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 oldBalance = balanceOf(from);
                // if from has insufficient balance here it will revert, but not nicely with ERC20InsufficientBalance
                // as handled in the ERC20 contract
                _balances[from].push(BalanceCheckpoint(uint48(block.number), oldBalance - amount));
            }
            if (to != address(0)) {
                uint256 oldBalance = balanceOf(to);
                _balances[to].push(BalanceCheckpoint(uint48(block.number), oldBalance + amount));
            }
        }
    }

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
        _checkpointBalances(from, to, value);
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
