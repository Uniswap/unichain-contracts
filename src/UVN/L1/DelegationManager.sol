// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IDelegationManager} from '../../interfaces/UVN/L1/IDelegationManager.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC20, ERC20Votes} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {console2} from 'forge-std/console2.sol';

contract DelegationManager is ERC20Votes, IDelegationManager, Ownable {
    constructor(address initialAdmin)
        ERC20('UNI DelegationManager', 'UNI-DM')
        EIP712('UNI DelegationManager', '1')
        Ownable(initialAdmin)
    {}

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) revert('Transfers disabled');
        super._update(from, to, value);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        console2.log('minting', amount, 'to', to);
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function updateDelegatee(address account, address newDelegatee) external onlyOwner {
        _delegate(account, newDelegatee);
    }
}
