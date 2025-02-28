// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributor, RewardDistributor} from '../../src/UVN/L2/RewardDistributor.sol';
import {MockRewardPuller} from '../mock/MockRewardPuller.sol';
import {MockVotesToken} from '../mock/MockVotesToken.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';

import 'forge-std/Test.sol';

abstract contract RewardDistributorTestBase is Test {
    uint256 constant DEFAULT_ATTESTATION_WINDOW_LENGTH = 10;

    RewardDistributor rd;
    MockRewardPuller mockRewardPuller;
    MockVotesToken mockVotesToken;
    Vm.Wallet operator = vm.createWallet('operator');

    using MessageHashUtils for bytes32;

    function setUp() public {
        vm.roll(1000);
        mockRewardPuller = new MockRewardPuller(1 ether);
        mockVotesToken = new MockVotesToken();
        rd = new RewardDistributor(
            address(this), mockVotesToken, mockRewardPuller, DEFAULT_ATTESTATION_WINDOW_LENGTH, 1000
        );
        mockVotesToken.mint(address(this), 1_000_000 ether);
        rd.grantRole(rd.PARAM_SETTER_ROLE(), address(this));
    }

    function signAttestation(uint256 blockNumber, bytes memory data) internal returns (bytes memory) {
        bytes32 dataHash = keccak256(abi.encode(blockNumber, bytes32(0), data));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operator, dataHash.toEthSignedMessageHash());
        return abi.encodePacked(r, s, v);
    }

    function assertStatus(uint256 blockNumber, IRewardDistributor.Status status) internal view {
        assertEq(uint8(rd.status(blockNumber)), uint8(status));
    }

    function assertStatus(uint256 blockNumber, IRewardDistributor.Status status, string memory message) internal view {
        assertEq(uint8(rd.status(blockNumber)), uint8(status), message);
    }

    function assertStatusRange(uint256 lower, uint256 upper, IRewardDistributor.Status status, string memory message)
        internal
        view
    {
        assertEq(uint8(rd.status(lower)), uint8(status), string(abi.encodePacked(message, ' (lower)')));
        assertEq(uint8(rd.status(upper)), uint8(status), string(abi.encodePacked(message, ' (upper)')));
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
        attestationPeriod = bound(attestationPeriod, rd.attestationWindowLength(), block.number - 1);
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
        attestationWindowLength = bound(attestationWindowLength, 1, 256);
        rd.setAttestationWindowLength(attestationWindowLength);
        // attest to the current window, on the next attestation the new window will be scheduled after the new `attestationWindowLength` blocks
        rd.attest(block.number - 1, bytes32(0), 'data', signAttestation(block.number, 'data'));
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attestationDelay = bound(attestationDelay, 0, attestationWindowLength - 1);
        // attest to the next window
        uint256 attestationBlockNumber = block.number - 1;
        vm.roll(block.number + attestationDelay);
        assertStatus(attestationBlockNumber, IRewardDistributor.Status.Active, 'Window should become active');
        vm.expectEmit();
        emit IRewardDistributor.AttestationWindowScheduled(
            attestationBlockNumber, attestationBlockNumber + attestationWindowLength
        );
        rd.attest(attestationBlockNumber, bytes32(0), 'data', signAttestation(attestationBlockNumber, 'data'));
    }

    function test_shouldInitializeWindowsCorrectlyAfterDelay(uint256 attestationWindowLength, uint256 attestationDelay)
        public
    {
        // Should the delay be larger than `attestationWindowLength`, it means that the next window is not scheduled automatically. In this case the current window will be extended until the next attestation occurs.
        attestationWindowLength = bound(attestationWindowLength, 1, 256);
        rd.setAttestationWindowLength(attestationWindowLength);
        // attest to the current window, on the next attestation the new window will be scheduled after the new `attestationWindowLength` blocks
        rd.attest(block.number - 1, bytes32(0), 'data', signAttestation(block.number, 'data'));
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attestationDelay = bound(attestationDelay, attestationWindowLength, attestationWindowLength + 512);
        // attest to the next window
        uint256 attestationBlockNumber = block.number + attestationDelay - 1;
        vm.roll(block.number + attestationDelay);
        assertEq(attestationBlockNumber, block.number - 1);
        uint256 originalAttestationBlockNumber = block.number - attestationDelay - 1;
        assertStatus(originalAttestationBlockNumber, IRewardDistributor.Status.Active, 'Window becomes active');
        assertStatus(attestationBlockNumber, IRewardDistributor.Status.Active, 'Window extends to the previous block');
        assertStatus(attestationBlockNumber + 1, IRewardDistributor.Status.Delayed, 'Next window is delayed');
        vm.expectEmit();
        emit IRewardDistributor.AttestationWindowExtended(originalAttestationBlockNumber, attestationBlockNumber);
        vm.expectEmit();
        emit IRewardDistributor.AttestationWindowScheduled(
            attestationBlockNumber, attestationBlockNumber + attestationWindowLength
        );
        rd.attest(attestationBlockNumber, bytes32(0), 'data', signAttestation(attestationBlockNumber, 'data'));
        assertStatus(
            attestationBlockNumber + 1, IRewardDistributor.Status.Scheduled, 'Delayed window should become scheduled'
        );
    }

    function test_shouldReturnCorrectStatusEndToEnd() public {
        uint256 blockNumber = block.number;
        assertStatus(blockNumber - 1, IRewardDistributor.Status.Active, 'Current window should be active');
        assertEq(rd.latestActiveWindow(), blockNumber - 1);
        assertStatusRange(
            blockNumber,
            blockNumber + rd.attestationWindowLength() - 1,
            IRewardDistributor.Status.Scheduled,
            'Next window should be scheduled'
        );
        assertStatusRange(
            blockNumber + rd.attestationWindowLength(),
            blockNumber + rd.attestationWindowLength() * 2 - 1,
            IRewardDistributor.Status.Pending,
            'Window after scheduled window should be pending'
        );
        assertStatus(
            blockNumber + rd.attestationWindowLength() * 2,
            IRewardDistributor.Status.NonExistent,
            'Window after scheduled window should not exist'
        );
        // move time forward one window length to activate scheduled window
        vm.roll(block.number + rd.attestationWindowLength() + 1);
        assertStatusRange(
            blockNumber,
            blockNumber + rd.attestationWindowLength() - 1,
            IRewardDistributor.Status.Active,
            'Scheduled window should become active'
        );
        assertEq(rd.latestActiveWindow(), blockNumber + rd.attestationWindowLength() - 1);
        assertStatusRange(
            blockNumber + rd.attestationWindowLength(),
            blockNumber + rd.attestationWindowLength() * 2 - 1,
            IRewardDistributor.Status.Pending,
            'Window after active should become pending until the next attestation schedules the window'
        );
        assertStatus(
            blockNumber + rd.attestationWindowLength() * 2,
            IRewardDistributor.Status.NonExistent,
            'Windows after pending window should not exist'
        );
        // move time forward one more window length, because there are no attestations during the pending window, it's extended and the next window will become delayed
        vm.roll(block.number + rd.attestationWindowLength());
        assertStatusRange(
            blockNumber,
            blockNumber + rd.attestationWindowLength() - 1,
            IRewardDistributor.Status.Active,
            'Scheduled window that became active should still be active'
        );
        assertStatusRange(
            blockNumber + rd.attestationWindowLength(),
            block.number - 1,
            IRewardDistributor.Status.Active,
            'Active window should extend to the last block'
        );
        assertEq(rd.latestActiveWindow(), block.number - 1);
        assertStatusRange(
            block.number,
            block.number + rd.attestationWindowLength() - 1,
            IRewardDistributor.Status.Delayed,
            'Next window should be delayed'
        );
        assertStatus(
            block.number + rd.attestationWindowLength(),
            IRewardDistributor.Status.NonExistent,
            'Window after delayed window should remain non existent'
        );
        // set attestation period so initial window is now finalized
        rd.setAttestationPeriod(rd.attestationWindowLength() * 2 + 1);
        assertStatus(blockNumber - 1, IRewardDistributor.Status.Finalized);
    }
}
