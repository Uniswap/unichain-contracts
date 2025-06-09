// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
/// @notice Library for managing scheduled windows

type NextWindow is uint128;

using NextWindowLib for NextWindow global;

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
