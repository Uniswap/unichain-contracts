// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library OperatorTokenLib {
    /// @dev Converts an operator address to a token id
    function toTokenId(address operator) internal pure returns (uint256) {
        return uint256(uint160(operator));
    }

    /// @dev Converts a token id to an operator address
    function toAddress(uint256 tokenId) internal pure returns (address) {
        return address(uint160(tokenId));
    }
}
