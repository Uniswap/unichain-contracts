// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import 'forge-std/Test.sol';

import {AttestationRewards} from '../../src/UVN/rewards/AttestationRewards.sol';
import {MockNetFeeSplitter} from '../mock/MockNetFeeSplitter.sol';
import {UVNSetupTest} from './UVNSetup.t.sol';

contract AttestationRewardsTest is UVNSetupTest {
    AttestationRewards internal attestationRewards;
    address internal _attestationRewards;

    MockNetFeeSplitter internal mockNetFeeSplitter;
    address internal _mockNetFeeSplitter;

    uint32 internal epochLength;

    function setUp() public override {
        super.setUp();

        mockNetFeeSplitter = new MockNetFeeSplitter();
        _mockNetFeeSplitter = address(mockNetFeeSplitter);

        attestationRewards = new AttestationRewards(_mockNetFeeSplitter, _delegationManager);
        _attestationRewards = address(attestationRewards);

        epochLength = uint32(attestationRewards.EPOCH_LENGTH());

        vm.roll(epochLength);

        vm.prank(_mockL2CrossDomainMessenger);
        stakeManager.sync(alice, 100, '');

        vm.prank(alice);
        delegationManager.delegate(operator);
    }

    function test_fuzz_Attest(uint32 _blockNumber, uint256 _value) public {
        vm.assume(_value > 0);
        // Assume start of epoch
        vm.assume(_blockNumber % epochLength == 0);
        // Assume not the first attestation (because currentEpoch - 1 would underflow in AttestationRewards)
        vm.assume(_blockNumber > epochLength);

        // Roll to the block number
        vm.roll(_blockNumber);

        (uint96 balanceLast0, uint96 balanceCurrent0, uint32 lastAttestedEpochNumber0) =
            attestationRewards.attesterData(operator);

        if (_blockNumber / epochLength != lastAttestedEpochNumber0) {
            vm.expectCall({
                callee: _mockNetFeeSplitter,
                data: abi.encodeWithSelector(MockNetFeeSplitter.withdrawFees.selector)
            });

            vm.mockCall({
                callee: _mockNetFeeSplitter,
                data: abi.encodeWithSelector(MockNetFeeSplitter.withdrawFees.selector),
                returnData: abi.encode(_value)
            });
        }

        vm.expectCall({callee: operator, data: ''});
        vm.mockCall({callee: operator, data: '', returnData: ''});
        vm.deal(operator, _value);

        vm.prank(operator);
        attestationRewards.attest(_blockNumber, blockhash(_blockNumber));

        (, uint96 _sharesCurrent,) = delegationManager.operatorData(operator);

        (uint96 balanceLast1, uint96 balanceCurrent1, uint32 lastAttestedEpochNumber1) =
            attestationRewards.attesterData(operator);
        // Last balance is current shares at the time of the last attestation (which was not updated)
        assertEq(balanceLast1, _sharesCurrent);
        // Current balance is the current shares in operatorData
        assertEq(balanceCurrent1, _sharesCurrent);
        // Last attested epoch number is the current epoch
        assertEq(lastAttestedEpochNumber1, _blockNumber / epochLength);
    }

    function test_Attest_usesLastBalance() public {
        uint32 nextEpoch = epochLength * 1;
        vm.roll(nextEpoch);

        vm.deal(_mockNetFeeSplitter, 1 ether);

        uint256 balance0 = operator.balance;

        (uint96 balanceLast0, uint96 balanceCurrent0, uint32 lastAttestedEpochNumber0) =
            attestationRewards.attesterData(operator);

        // Attester has not attested before
        assertEq(balanceLast0, 0);
        assertEq(balanceCurrent0, 0);
        assertEq(lastAttestedEpochNumber0, 0);

        vm.prank(operator);
        attestationRewards.attest(nextEpoch, blockhash(nextEpoch));

        // Assert that the operator's balance is unchanged
        assertEq(operator.balance, balance0);

        nextEpoch = nextEpoch + epochLength;

        // Roll to next epoch
        vm.roll(nextEpoch);

        (uint96 balanceLast1, uint96 balanceCurrent1, uint32 lastAttestedEpochNumber1) =
            attestationRewards.attesterData(operator);
        (, uint96 sharesCurrent,) = delegationManager.operatorData(operator);

        // Assert that the last balance is the sharesCurrent at the time of the last attestation (which was not updated)
        assertEq(balanceLast1, sharesCurrent);
        // Assert that the current balance is the sharesCurrent fetched from delegationManager
        assertEq(balanceCurrent1, sharesCurrent);
        // Assert that the last attested epoch number is the last epoch
        assertEq(lastAttestedEpochNumber1, (nextEpoch / epochLength) - 1);

        vm.prank(operator);
        attestationRewards.attest(nextEpoch, blockhash(nextEpoch));

        // Assert that the operator received rewards proportional to their balance
        assertEq(operator.balance, balance0 + 1 ether);
    }
}
