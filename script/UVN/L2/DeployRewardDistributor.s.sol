// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {RewardDistributor} from '../../../src/UVN/L2/RewardDistributor.sol';
import {EmptyRewardPuller} from '../../../test/mock/MockRewardPuller.sol';
import {MockVotesToken} from '../../../test/mock/MockVotesToken.sol';

import {Script} from 'forge-std/Script.sol';

contract DeployRewardDistributor is Script {
    function run() public {
        vm.startBroadcast();
        MockVotesToken mockVotesToken = new MockVotesToken();
        EmptyRewardPuller emptyRewardPuller = new EmptyRewardPuller();
        RewardDistributor rewardDistributor =
            new RewardDistributor(msg.sender, mockVotesToken, emptyRewardPuller, 30, 120);
        mockVotesToken.mint(msg.sender, 1000 ether);
        rewardDistributor.grantRole(rewardDistributor.PARAM_SETTER_ROLE(), msg.sender);
        vm.stopBroadcast();
    }
}
