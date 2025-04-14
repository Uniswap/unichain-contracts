// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';

interface IStakeTable is IVotes {
    /// @notice Returns the beneficiary address to receive rewards for the given operator address
    function beneficiary(address operator) external view returns (address);
}
