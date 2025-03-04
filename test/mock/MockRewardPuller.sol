// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {INetFeeSplitter} from '../../src/interfaces/FeeSplitter/INetFeeSplitter.sol';
import {IERC165, IRewardPuller} from '../../src/interfaces/UVN/L2/IRewardPuller.sol';
import {Vm} from 'forge-std/Vm.sol';

contract MockRewardPuller is IRewardPuller {
    Vm public immutable vm;
    uint256 private _amountPerBlock;
    uint256 private _lastDistribution;

    constructor(uint256 amountPerBlock) {
        vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        _amountPerBlock = amountPerBlock;
        _lastDistribution = block.number;
    }

    function setAmountPerBlock(uint256 amount) external {
        _amountPerBlock = amount;
    }

    function pullRewards() external returns (uint256) {
        uint256 amount = _amountPerBlock * (block.number - _lastDistribution);
        _lastDistribution = block.number;
        vm.deal(address(this), amount);
        (bool success,) = msg.sender.call{value: amount}('');
        return success ? amount : 0;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRewardPuller).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

contract EmptyRewardPuller is IRewardPuller {
    function pullRewards() external pure returns (uint256) {
        return 0;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRewardPuller).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
