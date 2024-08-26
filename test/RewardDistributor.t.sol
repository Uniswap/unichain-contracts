// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {L2StakeManager} from '../src/L2StakeManager.sol';
import {RewardDistributor} from '../src/RewardDistributor.sol';
import {MockL2CrossDomainMessenger} from './mock/MockL2CrossDomainMessenger.sol';
import 'forge-std/Test.sol';
import {GasSnapshot} from 'lib/forge-gas-snapshot/src/GasSnapshot.sol';

abstract contract Deployed is Test, GasSnapshot {
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
        l2StakeManager.registerDeposit(makeAddr('alice'), uint256(keccak256('alice')) % MAX_AMOUNT, makeAddr('alice'));
        vm.prank(address(mockL2CrossDomainMessenger));
        l2StakeManager.registerDeposit(makeAddr('bob'), uint256(keccak256('bob')) % MAX_AMOUNT, makeAddr('bob'));
        vm.prank(address(mockL2CrossDomainMessenger));
        l2StakeManager.registerDeposit(
            makeAddr('charlie'), uint256(keccak256('charlie')) % MAX_AMOUNT, makeAddr('charlie')
        );
        vm.prank(address(mockL2CrossDomainMessenger));
        l2StakeManager.registerDeposit(makeAddr('dave'), uint256(keccak256('dave')) % MAX_AMOUNT, makeAddr('dave'));
    }

    function rewardForBlock(uint256 blockNumber) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockNumber))) % 1 ether;
    }

    function depositReward(uint256 seed) public {
        uint256 randomReward = rewardForBlock(seed);
        vm.prank(paymentSplitter);
        (bool success,) = address(rewardDistributor).call{value: randomReward}('');
        snapLastCall('deposit reward');
        assert(success);
    }

    function attest(bytes memory account, bool vote) public {
        vm.prank(makeAddr(string(account)));
        rewardDistributor.attest(vm.getBlockNumber() - 2, blockhash(vm.getBlockNumber() - 2), vote);
        snapLastCall('attest');
    }

    function delegate(bytes memory account, bytes memory delegatee) public {
        vm.prank(makeAddr(string(account)));
        l2StakeManager.delegate(makeAddr(string(delegatee)));
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
            attest('alice', true);
            theoreticalRewards[0] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('alice')) / totalSupply;
            attest('bob', true);
            theoreticalRewards[1] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('bob')) / totalSupply;
            attest('charlie', true);
            theoreticalRewards[2] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('charlie')) / totalSupply;
            attest('dave', true);
            theoreticalRewards[3] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('dave')) / totalSupply;
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

    // Expect that rewards are paid out by delegated votes and not token balances
    function test_ShouldDistributeRewardsCorrectlyWithActiveDelegations() public {
        // alice delegates to bob
        delegate('alice', 'bob');
        // charlie delegates to dave
        delegate('charlie', 'dave');

        // assert that the delegations are active
        assertEq(l2StakeManager.delegates(makeAddr('alice')), makeAddr('bob'));
        assertEq(l2StakeManager.delegates(makeAddr('charlie')), makeAddr('dave'));
        assertEq(l2StakeManager.getVotes(makeAddr('alice')), 0);
        assertEq(l2StakeManager.getVotes(makeAddr('charlie')), 0);

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
            attest('alice', true);
            theoreticalRewards[0] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('alice')) / totalSupply;
            attest('bob', true);
            theoreticalRewards[1] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('bob')) / totalSupply;
            attest('charlie', true);
            theoreticalRewards[2] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('charlie')) / totalSupply;
            attest('dave', true);
            theoreticalRewards[3] +=
                rewardForBlock(vm.getBlockNumber() - 2) * l2StakeManager.getVotes(makeAddr('dave')) / totalSupply;
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

    // TODO:
    // - test that invalid votes are not rewarded
    // - test that invalid votes are rewarded if block is invalid
    // - test that rewards are not paid out if no votes are cast
    // - fuzzing tests
}
