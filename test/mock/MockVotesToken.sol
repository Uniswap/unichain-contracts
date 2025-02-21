// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20, ERC20Votes} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

contract MockVotesToken is ERC20Votes {
    constructor() ERC20('MockVotesToken', 'MVT') EIP712('MockVotesToken', '1') {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
