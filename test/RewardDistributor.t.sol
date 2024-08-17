// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {L2StakeManager} from '../src/L2StakeManager.sol';
import {RewardDistributor} from '../src/RewardDistributor.sol';
import {MockL2CrossDomainMessenger} from './mock/MockL2CrossDomainMessenger.sol';
import 'forge-std/Test.sol';

abstract contract Deployed is Test {
    L2StakeManager l2StakeManager;
    RewardDistributor rewardDistributor;
    MockL2CrossDomainMessenger mockL2CrossDomainMessenger;
    address l1StakeManager = makeAddr('l1StakeManager');
    address paymentSplitter = makeAddr('paymentSplitter');

    function setUp() public virtual {
        mockL2CrossDomainMessenger = new MockL2CrossDomainMessenger();
        vm.etch(0x4200000000000000000000000000000000000007, address(mockL2CrossDomainMessenger).code);
        mockL2CrossDomainMessenger = MockL2CrossDomainMessenger(0x4200000000000000000000000000000000000007);
        mockL2CrossDomainMessenger.setSender(l1StakeManager);
        l2StakeManager = new L2StakeManager(l1StakeManager);
        rewardDistributor = new RewardDistributor(paymentSplitter, address(l2StakeManager));
    }
}

abstract contract Deposited is Deployed {
    uint256 private constant MAX_AMOUNT = 100 ether;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(address(mockL2CrossDomainMessenger));
        l2StakeManager.registerDeposit(makeAddr('alice'), uint256(keccak256('alice')) % MAX_AMOUNT);
        vm.prank(address(mockL2CrossDomainMessenger));
        l2StakeManager.registerDeposit(makeAddr('bob'), uint256(keccak256('bob')) % MAX_AMOUNT);
        vm.prank(address(mockL2CrossDomainMessenger));
        l2StakeManager.registerDeposit(makeAddr('charlie'), uint256(keccak256('charlie')) % MAX_AMOUNT);
        vm.prank(address(mockL2CrossDomainMessenger));
        l2StakeManager.registerDeposit(makeAddr('dave'), uint256(keccak256('dave')) % MAX_AMOUNT);
    }

    function balanceOf(bytes memory account) public pure returns (uint256) {
        return uint256(keccak256(account)) % MAX_AMOUNT;
    }

    function rewardForBlock(uint256 blockNumber) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockNumber))) % 1 ether;
    }

    function depositReward(uint256 seed) public {
        uint256 randomReward = rewardForBlock(seed);
        vm.prank(paymentSplitter);
        (bool success,) = address(rewardDistributor).call{value: randomReward}('');
        assert(success);
    }

    function attest(bytes memory account) public {
        vm.prank(makeAddr(string(account)));
        rewardDistributor.attest(vm.getBlockNumber() - 2, blockhash(vm.getBlockNumber() - 2), true);
    }
}

contract RewardDistributorTest is Deposited {
    function test_ShouldDistributeRewardsCorrectly() public {
        uint256 iterations = 100;
        vm.roll(100);
        vm.deal(paymentSplitter, 2 ether * iterations);
        uint256[] memory theoreticalRewards = new uint256[](4);
        for (uint256 i = 0; i < iterations + 2; i++) {
            // increment block number
            vm.roll(vm.getBlockNumber() + 1);

            depositReward(vm.getBlockNumber());

            // skip first two blocks before starting to attest
            if (i < 2) continue;

            // attest
            uint256 totalSupply = l2StakeManager.totalSupply();
            attest('alice');
            theoreticalRewards[0] += rewardForBlock(vm.getBlockNumber() - 2) * balanceOf('alice') / totalSupply;
            attest('bob');
            theoreticalRewards[1] += rewardForBlock(vm.getBlockNumber() - 2) * balanceOf('bob') / totalSupply;
            attest('charlie');
            theoreticalRewards[2] += rewardForBlock(vm.getBlockNumber() - 2) * balanceOf('charlie') / totalSupply;
            attest('dave');
            theoreticalRewards[3] += rewardForBlock(vm.getBlockNumber() - 2) * balanceOf('dave') / totalSupply;
        }
        vm.roll(vm.getBlockNumber() + 100);
        rewardDistributor.finalize(makeAddr('alice'), 100);
        rewardDistributor.finalize(makeAddr('bob'), 100);
        rewardDistributor.finalize(makeAddr('charlie'), 100);
        rewardDistributor.finalize(makeAddr('dave'), 100);
        uint256 rewardAlice = rewardDistributor.earned(makeAddr('alice'));
        uint256 rewardBob = rewardDistributor.earned(makeAddr('bob'));
        uint256 rewardCharlie = rewardDistributor.earned(makeAddr('charlie'));
        uint256 rewardDave = rewardDistributor.earned(makeAddr('dave'));
        assertEq(rewardAlice, theoreticalRewards[0]);
        assertEq(rewardBob, theoreticalRewards[1]);
        assertEq(rewardCharlie, theoreticalRewards[2]);
        assertEq(rewardDave, theoreticalRewards[3]);
    }
}
