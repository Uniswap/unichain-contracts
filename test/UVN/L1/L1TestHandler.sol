// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStakingMiddleware, StakingMiddlewareDeployer} from '../../deployers/StakingMiddlewareDeployer.sol';
import {IUniStaker, UniStakerDeployer} from '../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../mock/MockVotesToken.sol';
import {Test} from 'forge-std/Test.sol';

contract L1TestHandler is Test {
    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    IStakingMiddleware stakingMiddleware;

    address delegator = makeAddr('delegator');
    address delegatee = makeAddr('delegatee');
    address operator = makeAddr('operator');
    address slasher = makeAddr('slasher');
    address slashingBeneficiary = makeAddr('slashing beneficiary');

    function setUp() public virtual {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        // TODO check optimal gas / contract size with and without viaIR and remove deployer if without viaIR
        stakingMiddleware = StakingMiddlewareDeployer.deploy(address(unistaker), address(this), 0, slashingBeneficiary);
    }
}
