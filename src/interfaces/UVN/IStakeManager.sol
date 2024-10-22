// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OperatorData} from "src/example-stakers/CrossDomainStaker/L2/StakeManager.sol";
import {IAttesterVaultFactory} from "src/lib/IAttesterVaultFactory.sol";

interface IStakeManager is IAttesterVaultFactory {
    function balanceOf(address staker) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
