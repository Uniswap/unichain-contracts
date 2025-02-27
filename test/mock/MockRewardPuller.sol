// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {INetFeeSplitter} from '../../src/interfaces/FeeSplitter/INetFeeSplitter.sol';
import {IERC165, IRewardPuller} from '../../src/interfaces/UVN/L2/IRewardPuller.sol';
import {Vm} from 'forge-std/Vm.sol';

contract MockRewardPuller is IRewardPuller {
    Vm public immutable vm;
    uint256 private _amount;

    constructor(uint256 amount) {
        vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        _amount = amount;
    }

    function setAmount(uint256 amount) external {
        _amount = amount;
    }

    function pullRewards() external returns (uint256) {
        vm.deal(address(this), _amount);
        (bool success,) = msg.sender.call{value: _amount}('');
        return success ? _amount : 0;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRewardPuller).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
