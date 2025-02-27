// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IRewardPuller is IERC165 {
    function pullRewards() external returns (uint256);
}
