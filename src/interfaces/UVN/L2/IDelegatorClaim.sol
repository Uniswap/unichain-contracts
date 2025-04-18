// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IDelegatorClaim {
    function reportDelegatorStake(address delegator, uint256 newStake) external;
}
