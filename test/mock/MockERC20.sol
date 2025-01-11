// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from 'solmate/tokens/ERC20.sol';

contract MockERC20 is ERC20 {
    constructor() ERC20('Mock', 'MOCK', 18) {}
}
