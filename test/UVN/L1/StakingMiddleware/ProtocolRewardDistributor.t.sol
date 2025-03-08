// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IProtocolRewardDistributor,
    ProtocolRewardDistributor
} from '../../../../src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol';
import {IUniStaker, UniStakerDeployer} from '../../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../../mock/MockVotesToken.sol';
import {UniStakerWrapperHarness} from './UniStakerWrapper.t.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'forge-std/Test.sol';

contract ProtocolRewardDistributorHarness is ProtocolRewardDistributor, UniStakerWrapperHarness {
    constructor(IUniStaker unistaker_) UniStakerWrapperHarness(unistaker_) {}

    function updateGlobalRewardCheckpoint() external {
        _updateGlobalRewardCheckpoint();
    }
}

contract UniStakerWrapperTest is Test {
    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    ProtocolRewardDistributorHarness protocolRewardDistributor;
    address delegatee = makeAddr('delegatee');

    function setUp() public {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        unistaker.setRewardNotifier(address(this), true);
        protocolRewardDistributor = new ProtocolRewardDistributorHarness(unistaker);
        // use up the first depositId 0
        unistaker.stake(0, delegatee);
    }

    function _depositor(uint256 i) internal returns (address) {
        return makeAddr(string(abi.encodePacked('depositor', i)));
    }

    function _recipient(uint256 i) internal returns (address) {
        return makeAddr(string(abi.encodePacked('recipient', i)));
    }

    function expectERC20Transfer(address from, address to, uint256 amount) internal {
        vm.expectEmit();
        emit IERC20.Transfer(from, to, amount);
    }

    function _randomUint96(uint256 seed, uint256 index) internal pure returns (uint96) {
        uint96 pseudoRandom = uint96(uint256(keccak256(abi.encodePacked(seed, index))) % type(uint96).max);
        return uint96(bound(uint256(pseudoRandom), 1, 100 ether));
    }

    function test_shouldDistributeRewardsCorrectly(uint256 seed) public {
        uint256 numDepositors = 10;
        uint96[] memory amounts = new uint96[](numDepositors);
        address[] memory depositors = new address[](numDepositors);
        address[] memory recipients = new address[](numDepositors);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < numDepositors; i++) {
            amounts[i] = _randomUint96(seed, i);
            depositors[i] = _depositor(i);
            recipients[i] = _recipient(i);
            stakeToken.mint(depositors[i], amounts[i]);
            vm.prank(depositors[i]);
            stakeToken.approve(address(protocolRewardDistributor), amounts[i]);
            vm.prank(depositors[i]);
            protocolRewardDistributor.depositIntoUniStaker(amounts[i], delegatee);
            totalAmount += amounts[i];
        }
        assertEq(protocolRewardDistributor.totalAmountStaked(), totalAmount);

        uint256 rewardAmount = _randomUint96(seed, numDepositors);
        rewardToken.mint(address(unistaker), rewardAmount);
        unistaker.notifyRewardAmount(rewardAmount);
        // reward duration is 30 days, wait for full amount
        vm.warp(block.timestamp + 30 days);
        assertApproxEqAbs(unistaker.unclaimedReward(address(protocolRewardDistributor)), rewardAmount, 1);
        rewardAmount = unistaker.unclaimedReward(address(protocolRewardDistributor));
        expectERC20Transfer(address(unistaker), address(protocolRewardDistributor), rewardAmount);
        vm.expectEmit();
        emit IProtocolRewardDistributor.RewardsAdded(rewardAmount);
        protocolRewardDistributor.updateGlobalRewardCheckpoint();
        for (uint256 i = 0; i < numDepositors; i++) {
            uint256 reward = protocolRewardDistributor.rewardsOf(depositors[i]);
            assertEq(reward, rewardAmount * amounts[i] / totalAmount);
            expectERC20Transfer(address(protocolRewardDistributor), recipients[i], reward);
            vm.expectEmit();
            emit IProtocolRewardDistributor.RewardsWithdrawn(depositors[i], recipients[i], reward);
            vm.prank(depositors[i]);
            uint256 withdrawn = protocolRewardDistributor.withdrawRewards(recipients[i]);
            assertEq(withdrawn, reward);
        }
    }
}
