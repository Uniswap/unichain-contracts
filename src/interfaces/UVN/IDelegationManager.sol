// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OperatorData} from '../../UVN/base/BaseStructs.sol';

interface IDelegationManager {
    function totalDelegatedSupply() external view returns (uint256);
    function operatorData(address operator) external view returns (OperatorData memory);
}
