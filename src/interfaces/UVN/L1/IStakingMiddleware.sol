// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ISlashingManager} from './StakingMiddleware/ISlashingManager.sol';

interface IStakingMiddleware is ISlashingManager {
    /// @notice Returns the nonces used for delegation by signature
    function nonces(address owner) external view returns (uint256);
}
