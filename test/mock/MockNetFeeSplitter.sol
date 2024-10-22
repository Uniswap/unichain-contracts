// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockNetFeeSplitter {
    receive() external payable {}

    function withdrawFees(address to) external {
        payable(to).transfer(address(this).balance);
    }
}
