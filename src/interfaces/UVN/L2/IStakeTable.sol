// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';

/// @title IStakeTable
/// @notice The reward distributor contract pulls voting weights and the beneficiary for reward distribution from contracts implementing this interface.
interface IStakeTable is IVotes {
    /// @notice Returns the beneficiary address to receive rewards for the given operator address
    function beneficiary(address operator) external view returns (address);
}
