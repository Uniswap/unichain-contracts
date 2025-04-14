// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IUniStaker} from '../../src/interfaces/UVN/L1/IUnistaker.sol';
import {Vm} from 'forge-std/Vm.sol';

library UniStakerDeployer {
    function deploy(address rewardToken, address stakeToken, address admin) internal returns (IUniStaker) {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        bytes memory args = abi.encode(rewardToken, stakeToken, admin);
        bytes memory initCode = abi.encodePacked(vm.getCode('out/UniStaker.sol/UniStaker.json'), args);
        address unistaker;
        assembly {
            unistaker := create(0, add(initCode, 0x20), mload(initCode))
        }
        return IUniStaker(unistaker);
    }
}
