// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddleware} from '../../src/interfaces/UVN/L1/IStakingMiddleware.sol';
import {Vm} from 'forge-std/Vm.sol';

library StakingMiddlewareDeployer {
    function deploy(address unistaker, address initialAdmin, uint256 withdrawalDelay, address slashingBeneficiary)
        internal
        returns (IStakingMiddleware)
    {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        bytes memory args = abi.encode(unistaker, initialAdmin, withdrawalDelay, slashingBeneficiary);
        bytes memory initCode = abi.encodePacked(vm.getCode('out/StakingMiddleware.sol/StakingMiddleware.json'), args);
        address stakingmiddleware;
        assembly {
            stakingmiddleware := create(0, add(initCode, 0x20), mload(initCode))
        }
        return IStakingMiddleware(stakingmiddleware);
    }
}
