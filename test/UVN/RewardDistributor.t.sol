// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributor, RewardDistributor} from '../../src/UVN/L2/RewardDistributor.sol';
import {MockFeeSplitter} from '../mock/MockFeeSplitter.sol';
import {MockVotesToken} from '../mock/MockVotesToken.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';

import 'forge-std/Test.sol';

abstract contract RewardDistributorTestBase is Test {
    uint256 constant DEFAULT_ATTESTATION_WINDOW_LENGTH = 10;

    RewardDistributor rd;
    MockFeeSplitter mockFeeSplitter;
    MockVotesToken mockVotesToken;
    Vm.Wallet operator = vm.createWallet('operator');

    using MessageHashUtils for bytes32;

    function setUp() public {
        vm.roll(1000);
        mockFeeSplitter = new MockFeeSplitter(1 ether);
        mockVotesToken = new MockVotesToken();
        rd = new RewardDistributor(
            address(this), address(mockFeeSplitter), address(mockVotesToken), DEFAULT_ATTESTATION_WINDOW_LENGTH, 1000
        );
        mockVotesToken.mint(address(this), 1_000_000 ether);
        rd.grantRole(rd.PARAM_SETTER_ROLE(), address(this));
    }

    function signAttestation(uint256 blockNumber, bytes memory data) internal returns (bytes memory) {
        bytes32 dataHash = keccak256(abi.encode(blockNumber, bytes32(0), data));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operator, dataHash.toEthSignedMessageHash());
        return abi.encodePacked(r, s, v);
    }
}

contract RewardDistributorTest is RewardDistributorTestBase {
    function test_shouldNotBeAbleToAttestFutureBlock(uint256 blockNumber) public {
        blockNumber = bound(blockNumber, block.number, type(uint256).max);
        vm.expectRevert(IRewardDistributor.NoBlockHashAvailable.selector);
        rd.attest(blockNumber, bytes32(0), new bytes(0), new bytes(0));
    }

    function test_shouldNotBeAbleToAttestBlockBeforeAttestationPeriod(uint256 blockNumber, uint256 attestationPeriod)
        public
    {
        attestationPeriod = bound(attestationPeriod, 1, block.number - 1);
        rd.setAttestationPeriod(attestationPeriod);
        blockNumber = bound(blockNumber, 0, block.number - rd.attestationPeriod() - 1);
        vm.expectRevert(IRewardDistributor.AttestationPeriodPassed.selector);
        rd.attest(blockNumber, bytes32(0), new bytes(0), new bytes(0));
    }

    function test_shouldNotBeAbleToAttestSameBlockTwice() public {
        uint256 blockNumber = block.number - 1;
        bytes memory signatureA = signAttestation(blockNumber, 'dataA');
        bytes memory signatureB = signAttestation(blockNumber, 'dataB');

        rd.attest(blockNumber, bytes32(0), 'dataA', signatureA);
        vm.expectRevert(IRewardDistributor.BlockAlreadyAttested.selector);
        rd.attest(blockNumber, bytes32(0), 'dataB', signatureB);
    }

    function test_shouldInitializeWindowsCorrectly(uint256 attestationWindowLength, uint256 attestationDelay) public {
        // Usually an attestation will occur on the first block of the next window, and the next window will be scheduled automatically after the `attestationWindowLength` blocks. If there is a delay of less than `attestationWindowLength` blocks, the next window will still be scheduled the same as if there was no delay.
        // Should the delay be larger than `attestationWindowLength`, it means that the next window is not scheduled automatically. In this case the current window will be extended until the next attestation occurs.
        attestationWindowLength = bound(attestationWindowLength, 1, 256);
        rd.setAttestationWindowLength(attestationWindowLength);
        // attest to the current window, on the next attestation the new window will be scheduled after the new `attestationWindowLength` blocks
        rd.attest(block.number - 1, bytes32(0), 'data', signAttestation(block.number, 'data'));
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        // Half of the attestation intervals will be shorter or equal to the attestation window length on average, meaning that the next window will be not extended
        attestationDelay = bound(attestationDelay, 0, attestationWindowLength * 2);
        if (attestationDelay > attestationWindowLength) {
            // the other half will be larger, randomize up to 512 blocks
            attestationDelay = bound(attestationDelay, attestationWindowLength + 1, 512);
        }
        // attest to the next window
        uint256 attestationBlockNumber =
            attestationDelay >= attestationWindowLength ? block.number + attestationDelay : block.number;
        vm.roll(block.number + attestationDelay);
        if (attestationDelay >= attestationWindowLength) {
            uint256 originalAttestationBlockNumber = block.number - attestationDelay - 1;
            vm.expectEmit();
            emit IRewardDistributor.AttestationWindowExtended(
                originalAttestationBlockNumber, attestationBlockNumber - 1
            );
        }
        vm.expectEmit();
        emit IRewardDistributor.AttestationWindowScheduled(
            attestationBlockNumber - 1, attestationBlockNumber + attestationWindowLength - 1, 1 ether
        );
        rd.attest(attestationBlockNumber - 1, bytes32(0), 'data', signAttestation(attestationBlockNumber, 'data'));
        uint256 waitForNextWindow = attestationDelay < attestationWindowLength
            ? attestationWindowLength - attestationDelay
            : attestationWindowLength;
        vm.roll(block.number + waitForNextWindow);
    }
}
