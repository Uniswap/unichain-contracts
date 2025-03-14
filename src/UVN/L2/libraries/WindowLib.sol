// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributor} from '../../../interfaces/UVN/L2/IRewardDistributor.sol';
import {Search} from './Search.sol';

struct Window {
    bool finalized;
    /// @dev the reward to distribute to the operators that voted for the most voted hash in this window
    uint96 rewardETH;
    /// @dev the index of the window in the list of window block numbers
    uint32 index;
    /// @dev the total supply of stake eligible to vote in this window
    uint96 votingTotalSupply;
    /// @dev the number of votes that attested to the most voted hash in this window
    uint96 mostVotedHashVotes;
    /// @dev pointer to the next window
    NextWindow nextWindow;
    /// @dev the actual block hash of the last block in this window
    bytes32 blockHash;
    /// @dev the most voted for block hash in this window
    bytes32 mostVotedBlockHash;
    /// @dev the most voted for hash in this window that includes additional data
    bytes32 mostVotedHash;
    /// @dev the number of votes for each hash that was attested to in this window
    mapping(bytes32 votedHash => uint256 votes) attestations;
}

struct Windows {
    /// @dev List of block numbers identifying the windows
    uint256[] blockNumbers;
    uint256 windowLength;
    mapping(uint256 blockNumber => Window window) windows;
}

type NextWindow is uint128;

using WindowLib for Windows global;
using WindowLib for Window global;
using NextWindowLib for NextWindow global;

/// @notice Library for managing active and scheduled windows
library WindowLib {
    using Search for uint256[];

    /// @notice Activates a new scheduled window, automatically schedules the next window
    function activate(Windows storage $, uint256 blockNumber, uint256 reward, uint256 votingSupply)
        internal
        returns (uint256 nextWindow)
    {
        bytes32 blockHash = blockhash(blockNumber);
        // @audit safe guard, returns 0 for older than 256 blocks, should not happen because of the check when setting the attestation window length
        assert(blockHash != bytes32(0));
        uint256 windowLength = $.windowLength;
        $.windows[blockNumber].nextWindow = NextWindowLib.setBlockNumber(blockNumber + windowLength);
        $.windows[blockNumber].blockHash = blockhash(blockNumber);
        $.windows[blockNumber].votingTotalSupply = uint96(votingSupply);
        $.windows[blockNumber].rewardETH = uint96(reward);
        $.windows[blockNumber].index = uint32($.blockNumbers.length);
        $.blockNumbers.push(blockNumber);
        return blockNumber + windowLength;
    }

    /// @notice Should a delay occur, the scheduled window is extended to the previous block number before activation
    function extendScheduledWindow(Window storage window) internal {
        window.nextWindow = NextWindowLib.extendWindow(window.nextWindow);
    }

    /// @notice Records an attestation and their votes for a given block hash
    function attest(Windows storage $, uint256 blockNumber, bytes32 blockHash, bytes32 votedHash, uint256 votes)
        internal
    {
        Window storage window = $.windows[blockNumber];
        if (!window.exists()) revert IRewardDistributor.WindowNotFound();
        window.attestations[votedHash] += votes;
        uint256 totalVotesAttested = window.attestations[votedHash];
        if (totalVotesAttested > window.mostVotedHashVotes) {
            window.mostVotedBlockHash = blockHash;
            window.mostVotedHash = votedHash;
            window.mostVotedHashVotes = uint96(totalVotesAttested);
        }
    }

    /// @notice Records a reward for the scheduled window
    function recordReward(Windows storage $, uint256 reward) internal returns (uint256 blockNumber) {
        Window storage scheduledWindow = $.current();
        NextWindow nextWindow = scheduledWindow.nextWindow;
        scheduledWindow.nextWindow = nextWindow.addReward(reward);
        return nextWindow.blockNumber();
    }

    /// @notice Sets the length of the attestation window
    function setWindowLength(Windows storage $, uint256 windowLength) internal {
        $.windowLength = windowLength;
    }

    /// @notice Returns the block number of the current window
    function currentBlockNumber(Windows storage $) internal view returns (uint256) {
        return $.blockNumbers[$.blockNumbers.length - 1];
    }

    /// @notice Returns the current window
    function current(Windows storage $) internal view returns (Window storage window) {
        return $.windows[$.currentBlockNumber()];
    }

    /// @notice Finds the window for a given block number
    /// @return window The block number of the window that contains the block number
    /// @return exists Whether the window exists
    function find(Windows storage $, uint256 blockNumber) internal view returns (uint256 window, bool) {
        uint256 index = _findWindowIndex($, blockNumber);
        if (index == type(uint256).max) {
            return (type(uint256).max, false);
        }
        return ($.blockNumbers[index], true);
    }

    /// @notice Checks if the scheduled window is delayed
    function isNextWindowDelayed(Windows storage $) internal view returns (bool) {
        Window storage currentWindow = $.current();
        return _isWindowDelayed(currentWindow.nextWindow.blockNumber(), $.windowLength);
    }

    /// @notice Returns the current attestation window length
    function currentWindowLength(Windows storage $) internal view returns (uint256) {
        return $.windowLength;
    }

    /// @notice Returns the block number of a given window
    function blockNumberOf(Windows storage $, Window storage window) internal view returns (uint256) {
        return $.blockNumbers[window.index];
    }

    /// @notice Checks if a window is finalized
    function isFinalized(Window storage window) internal view returns (bool) {
        return window.finalized;
    }

    /// @notice Checks if a window exists
    function exists(Window storage window) internal view returns (bool) {
        return window.nextWindow.blockNumber() != 0;
    }

    /// @dev performs an exponential search first to find a range that contains the block number and reduces the search space for recent block numbers
    function _findWindowIndex(Windows storage $, uint256 blockNumber) private view returns (uint256) {
        uint256 index = $.windows[blockNumber].index;
        // first window has an index of 0, needs to be retrieved via binary search
        if (index != 0) return index;
        (uint256 left, uint256 right) = $.blockNumbers.exponentialSearchDesc(blockNumber);
        if (left == right) return left;
        if (right == type(uint256).max) return type(uint256).max;
        return $.blockNumbers.binarySearchRoundingUp(blockNumber, left, right);
    }

    function _isWindowDelayed(uint256 windowEnd, uint256 windowLength) private view returns (bool) {
        return block.number > windowEnd + windowLength;
    }
}

/// @notice Library for managing scheduled windows
library NextWindowLib {
    /// @notice Returns the block number and reward for a given scheduled window
    function get(NextWindow nextWindow) internal pure returns (uint256 blockNumber_, uint256 reward_) {
        uint128 value = NextWindow.unwrap(nextWindow);
        return (value >> 96, value & type(uint96).max);
    }

    /// @notice Sets the block number for a new scheduled window
    function setBlockNumber(uint256 blockNumber_) internal pure returns (NextWindow) {
        return _encode(blockNumber_, 0);
    }

    /// @notice Adds a reward to the scheduled window
    function addReward(NextWindow nextWindow, uint256 reward_) internal pure returns (NextWindow) {
        return _encode(nextWindow.blockNumber(), nextWindow.reward() + reward_);
    }

    /// @notice Extends the scheduled window to the previous block number upon delay
    function extendWindow(NextWindow nextWindow) internal view returns (NextWindow) {
        return _encode(block.number - 1, nextWindow.reward());
    }

    /// @notice Returns the block number of the scheduled window
    function blockNumber(NextWindow nextWindow) internal pure returns (uint256 blockNumber_) {
        return NextWindow.unwrap(nextWindow) >> 96;
    }

    /// @notice Returns the reward of the scheduled window
    function reward(NextWindow nextWindow) internal pure returns (uint256 reward_) {
        return NextWindow.unwrap(nextWindow) & type(uint96).max;
    }

    function _encode(uint256 blockNumber_, uint256 reward_) private pure returns (NextWindow) {
        return NextWindow.wrap(uint128(uint32(blockNumber_)) << 96 | uint96(reward_));
    }
}
