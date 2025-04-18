// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC7751 {
    /// @notice ERC-7751 error wrapping reverts by service contracts
    error WrappedError(address target, bytes4 selector, bytes reason, bytes details);
}
