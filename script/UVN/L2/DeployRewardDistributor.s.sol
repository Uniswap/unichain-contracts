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
        new RewardDistributor(msg.sender, mockVotesToken, emptyRewardPuller, 12, 120);
        vm.stopBroadcast();
    }
}
