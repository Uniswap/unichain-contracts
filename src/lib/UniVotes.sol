// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

/// @title UniVotes
/// @notice This contract tracks voting units, balance, and validator information for L2 accounts
/// @dev implementation inspired by OpenZeppelin's Votes.sol
abstract contract UniVotes is ERC20, EIP712 {
    struct Checkpoint {
        uint256 fromBlock;
        uint256 balance;
        uint256 delegatedVotes;
        bool active;
    }

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    /// @notice totalCheckpoints tracks the total number of votes delegated
    Checkpoint[] private _totalCheckpoints;
    /// @notice mapping of account to checkpoints
    mapping(address => Checkpoint[]) private _checkpoints;
    /// @notice mapping of account to delegatee
    mapping(address account => address) private _delegatee;

    bytes32 private constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegatee[account];
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     * @notice necessarily enforces that votes are 1:1 with token balance
     */
    function _delegate(address account, address delegatee) internal virtual {
        address oldDelegate = delegates(account);
        _delegatee[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        // the max amount of votes that can be delegated is the current balance of the account
        _moveDelegateVotes(oldDelegate, delegatee, balanceOf(account));
    }

    /// @notice get the latest checkpoint for an account
    function latest(address account) public view returns (Checkpoint memory) {
        if (_checkpoints[account].length == 0) {
            return Checkpoint({
                fromBlock: block.number,
                balance: balanceOf(account),
                delegatedVotes: 0, // account is not delegated by default
                active: true
            });
        }
        return _checkpoints[account][_checkpoints[account].length - 1];
    }

    /// @notice get the latest total checkpoint
    function latestTotalCheckpoint() public view returns (Checkpoint memory) {
        // if no mints or burns yet we initialize here
        if (_totalCheckpoints.length == 0) {
            return Checkpoint({fromBlock: block.number, balance: totalSupply()});
        }
        return _totalCheckpoints[_totalCheckpoints.length - 1];
    }

    /// @notice get the checkpoint for an account at fromBlock or before
    /// @dev preforms a binary search and returns the lower bound
    function getPastCheckpoint(address account, uint256 fromBlock) public view returns (Checkpoint memory) {
        Checkpoint[] memory checkpoints = _checkpoints[account];
        // binary search for fromBlock
        uint256 length = checkpoints.length;
        uint256 mid = length / 2;
        uint256 low = 0;
        uint256 high = length - 1;
        while (low < high) {
            mid = (low + high) / 2;
            if (checkpoints[mid].fromBlock == fromBlock) {
                return checkpoints[mid];
            } else if (checkpoints[mid].fromBlock < fromBlock) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        // if fromBlock is not found, return the closest checkpoint before fromBlock
        if (low > 0 && checkpoints[low].fromBlock > fromBlock) {
            return checkpoints[low - 1];
        } else {
            return checkpoints[low];
        }
    }

    /// @notice get the total checkpoint at fromBlock or before
    /// @dev preforms a binary search and returns the lower bound
    function getPastTotalCheckpoint(uint256 fromBlock) public view returns (Checkpoint memory) {
        // binary search for fromBlock
        uint256 length = _totalCheckpoints.length;
        uint256 mid = length / 2;
        uint256 low = 0;
        uint256 high = length - 1;
        while (low < high) {
            mid = (low + high) / 2;
            if (_totalCheckpoints[mid].fromBlock == fromBlock) {
                return _totalCheckpoints[mid];
            } else if (_totalCheckpoints[mid].fromBlock < fromBlock) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        // if fromBlock is not found, return the closest checkpoint before fromBlock
        if (low > 0 && _totalCheckpoints[low].fromBlock > fromBlock) {
            return _totalCheckpoints[low - 1];
        } else {
            return _totalCheckpoints[low];
        }
    }

    /// Internal and private functions

    /**
     * @dev Updates token balances and voting units on transfer
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        _transferVotingUnits(from, to, value);
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. TotalVotingUnits will be adjusted with mints and burns.
     */
    function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            Checkpoint memory latestTotalCheckpoint = latestTotalCheckpoint();
            _totalCheckpoints.push(
                Checkpoint({
                    fromBlock: block.number,
                    balance: totalSupply()
                })
            );
        }
        if (to == address(0)) {
            Checkpoint memory latestTotalCheckpoint = latestTotalCheckpoint();
            _totalCheckpoints.push(
                Checkpoint({
                    fromBlock: block.number,
                    balance: totalSupply()
                })
            );
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(address from, address to, uint256 amount) private {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                Checkpoint memory latestFrom = latest(from);
                Checkpoint memory checkpoint = _push(
                    from,
                    latestFrom.balance, // balance is not modified here because delegation does not affect balance
                    latestFrom.delegatedVotes - amount,
                    latestFrom.active
                );
                emit DelegateVotesChanged(from, latestFrom.delegatedVotes, checkpoint.delegatedVotes);
            }
            if (to != address(0)) {
                Checkpoint memory latestTo = latest(to);
                Checkpoint memory checkpoint = _push(
                    to,
                    latestTo.balance, // balance is not modified here because delegation does not affect balance
                    latestTo.delegatedVotes - amount,
                    latestTo.active
                );
                emit DelegateVotesChanged(to, latestTo.delegatedVotes, checkpoint.delegatedVotes);
            }
        }
    }

    /// @notice push a new checkpoint for an account
    function _push(address account, uint256 balance, uint256 delegatedVotes, bool active)
        internal
        returns (Checkpoint memory checkpoint)
    {
        checkpoint =
            Checkpoint({fromBlock: block.number, balance: balance, delegatedVotes: delegatedVotes, active: active});
        _checkpoints[account].push(checkpoint);
    }
}
