// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegatorClaim {
    function reportDelegatorStake(address delegator, uint256 newStake) external;
}
