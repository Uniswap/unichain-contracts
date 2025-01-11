// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockNetFeeSplitter {
    receive() external payable {}

    function withdrawFees(address to) external returns (uint256) {
        uint256 balance = address(this).balance;
        (bool success,) = payable(to).call{value: balance}('');
        if (!success) revert();
        return balance;
    }
}
