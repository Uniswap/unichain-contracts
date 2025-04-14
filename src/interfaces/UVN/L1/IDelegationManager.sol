// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IDelegationManager {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function updateDelegatee(address account, address newDelegatee) external;
}
