// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakingMiddleware} from '../../../src/UVN/L1/StakingMiddleware.sol';
import {IUniStaker, UniStakerDeployer} from '../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../mock/MockVotesToken.sol';
import {Test} from 'forge-std/Test.sol';

contract L1TestHandler is Test {
    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    StakingMiddleware stakingMiddleware;

    address delegatee = makeAddr('delegatee');
    address operator = makeAddr('operator');
    address slashingBeneficiary = makeAddr('slashing beneficiary');

    function setUp() public virtual {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        stakingMiddleware = new StakingMiddleware(unistaker, address(this), 0, slashingBeneficiary);
    }
}
