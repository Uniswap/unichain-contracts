// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IStakeManager {
    function balanceOf(address staker) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
