// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IFeeSplitter} from '../../src/interfaces/FeeSplitter/IFeeSplitter.sol';
import {INetFeeSplitter} from '../../src/interfaces/FeeSplitter/INetFeeSplitter.sol';
import {Vm} from 'forge-std/Vm.sol';

contract MockFeeSplitter is IFeeSplitter {
    Vm public immutable vm;
    uint256 private _amount;
    MockNetFeeSplitter public immutable netFeeSplitter;

    constructor(uint256 amount) {
        vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        _amount = amount;
        netFeeSplitter = new MockNetFeeSplitter();
    }

    function setAmount(uint256 amount) external {
        _amount = amount;
    }

    function distributeFees() external override returns (bool) {
        vm.deal(address(netFeeSplitter), _amount);
        return _amount != 0;
    }

    function OPTIMISM_WALLET() external pure override returns (address) {
        return address(0);
    }

    function NET_FEE_RECIPIENT() external view override returns (address) {
        return address(netFeeSplitter);
    }

    function L1_FEE_RECIPIENT() external pure override returns (address) {
        return address(0);
    }
}

contract MockNetFeeSplitter is INetFeeSplitter {
    constructor() {}

    function transferAllocation(address oldRecipient, address newRecipient, uint256 allocation) external {}

    function transferAllocationAndSetSetter(
        address oldRecipient,
        address newRecipient,
        address newSetter,
        uint256 allocation
    ) external {}

    function transferSetter(address recipient, address newSetter) external {}

    function withdrawFees(address to) external returns (uint256 amount) {
        amount = address(this).balance;
        (bool success,) = to.call{value: amount}('');
        if (!success) revert WithdrawalFailed();
    }

    function earnedFees(address account) external view returns (uint256) {}

    function balanceOf(address recipient) external view returns (uint256) {}

    function setterOf(address recipient) external view returns (address) {}
}
