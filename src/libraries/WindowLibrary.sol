// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

type NextWindow is uint256;

using WindowLibrary for NextWindow global;

library WindowLibrary {
    function encode(uint256 blockNumber_, uint256 reward) internal pure returns (NextWindow) {
        return NextWindow.wrap(blockNumber_ << 128 | reward);
    }

    function decode(NextWindow nextWindow) internal pure returns (uint256 blockNumber_, uint256 reward) {
        uint256 value = NextWindow.unwrap(nextWindow);
        return (value >> 128, value & type(uint128).max);
    }

    function setNextBlockNumber(uint256 blockNumber_) internal pure returns (NextWindow) {
        return encode(blockNumber_, 0);
    }

    function blockNumber(NextWindow nextWindow) internal pure returns (uint256 blockNumber_) {
        return NextWindow.unwrap(nextWindow) >> 128;
    }
}
