// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributor, RewardDistributor} from '../../src/UVN/L2/RewardDistributor.sol';
import {MockRewardPuller} from '../mock/MockRewardPuller.sol';
import {MockVotesToken} from '../mock/MockVotesToken.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';

import 'forge-std/Test.sol';

abstract contract RewardDistributorTestBase is Test {
    uint256 constant DEFAULT_ATTESTATION_WINDOW_LENGTH = 10;
    uint256 constant DEFAULT_ATTESTATION_PERIOD = 256;

    RewardDistributor rd;
    MockRewardPuller mockRewardPuller;
    MockVotesToken mockVotesToken;
    Vm.Wallet operator = vm.createWallet('operator');
    Vm.Wallet operator2 = vm.createWallet('operator2');

    using MessageHashUtils for bytes32;

    function setUp() public {
        mockVotesToken = new MockVotesToken();
        mockVotesToken.mint(operator.addr, 67 ether);
        mockVotesToken.mint(operator2.addr, 33 ether);
        vm.roll(DEFAULT_ATTESTATION_PERIOD);
        mockRewardPuller = new MockRewardPuller(1 ether);
        rd = new RewardDistributor(
            address(this),
            mockVotesToken,
            mockRewardPuller,
            DEFAULT_ATTESTATION_WINDOW_LENGTH,
            DEFAULT_ATTESTATION_PERIOD
        );
        rd.grantRole(rd.PARAM_SETTER_ROLE(), address(this));
    }

    function attest() internal {
        attest(operator, block.number - 1);
    }

    function attest(Vm.Wallet memory operator_) internal {
        attest(operator_, block.number - 1);
    }

    function attest(uint256 blockNumber) internal {
        attest(operator, blockNumber);
    }

    function attest(Vm.Wallet memory operator_, uint256 blockNumber) internal {
        attest(operator_, blockNumber, blockhash(blockNumber));
    }

    function attest(Vm.Wallet memory operator_, uint256 blockNumber, bytes32 blockHash) internal {
        rd.attest(
            blockNumber, blockHash, 'data', signAttestation(operator_, blockNumber, blockHash, 'data'), bytes32(0)
        );
    }

    function signAttestation(uint256 blockNumber, bytes memory data) internal returns (bytes memory) {
        return signAttestation(operator, blockNumber, blockhash(blockNumber), data);
    }

    function signAttestation(Vm.Wallet memory operator_, uint256 blockNumber, bytes32 blockHash, bytes memory data)
        internal
        returns (bytes memory)
    {
        bytes32 dataHash = keccak256(abi.encode(blockNumber, blockHash, data));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operator_, dataHash.toEthSignedMessageHash());
        return abi.encodePacked(r, s, v);
    }

    function assertStatus(uint256 blockNumber, IRewardDistributor.Status status) internal view {
        assertEq(uint8(rd.status(blockNumber)), uint8(status));
    }

    function assertStatus(uint256 blockNumber, IRewardDistributor.Status status, string memory message) internal view {
        assertEq(uint8(rd.status(blockNumber)), uint8(status), message);
    }

    function assertAttestationResult(
        uint256 blockNumber,
        IRewardDistributor.AttestationResult result,
        string memory message
    ) internal view {
        assertEq(uint8(rd.attestationResult(blockNumber)), uint8(result), message);
    }

    function assertStatusRange(uint256 lower, uint256 upper, IRewardDistributor.Status status, string memory message)
        internal
        view
    {
        assertEq(uint8(rd.status(lower)), uint8(status), string(abi.encodePacked(message, ' (lower)')));
        assertEq(uint8(rd.status(upper)), uint8(status), string(abi.encodePacked(message, ' (upper)')));
    }

    function expectNotEmit(bytes32 selector, string memory message) internal {
        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == selector) {
                revert(message);
            }
        }
    }
}

contract RewardDistributorTest is RewardDistributorTestBase {
    function test_shouldNotBeAbleToAttestFutureBlock(uint256 blockNumber) public {
        blockNumber = bound(blockNumber, block.number, type(uint256).max);
        vm.expectRevert(IRewardDistributor.NoBlockHashAvailable.selector);
        rd.attest(blockNumber, bytes32(0), new bytes(0), new bytes(0), bytes32(0));
    }

    function test_shouldNotBeAbleToAttestBlockBeforeAttestationPeriod(uint256 blockNumber, uint256 attestationPeriod)
        public
    {
        attestationPeriod = bound(attestationPeriod, rd.attestationWindowLength(), block.number - 1);
        rd.setAttestationPeriod(attestationPeriod);
        blockNumber = bound(blockNumber, 0, block.number - rd.attestationPeriod() - 1);
        vm.expectRevert(IRewardDistributor.AttestationPeriodPassed.selector);
        rd.attest(blockNumber, bytes32(0), new bytes(0), new bytes(0), bytes32(0));
    }

    function test_shouldNotBeAbleToAttestSameBlockTwice() public {
        uint256 blockNumber = block.number - 1;
        bytes memory signatureA = signAttestation(blockNumber, 'dataA');
        bytes memory signatureB = signAttestation(blockNumber, 'dataB');

        rd.attest(blockNumber, blockhash(blockNumber), 'dataA', signatureA, bytes32(0));
        vm.expectRevert(IRewardDistributor.BlockAlreadyAttested.selector);
        rd.attest(blockNumber, blockhash(blockNumber), 'dataB', signatureB, bytes32(0));
    }

    // this only works on the nightly version of forge right now
    /// forge-config: default.isolate = true
    function test_gasAttestation() public {
        // initialize operators to not skew gas metering
        attest(operator);
        attest(operator2);

        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attest(operator);
        vm.snapshotGasLastCall('schedulingAttestation');

        attest(operator2);
        vm.snapshotGasLastCall('rawAttestation');

        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH * 10);
        attest(operator2);
        vm.snapshotGasLastCall('delayedAttestation');

        rd.setAttestationPeriod(DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attest(operator);
        vm.snapshotGasLastCall('finalizingAttestation');
    }

    function test_shouldInitializeWindowsCorrectly(uint256 attestationWindowLength, uint256 attestationDelay) public {
        // Usually an attestation will occur on the first block of the next window, and the next window will be scheduled automatically after the `attestationWindowLength` blocks. If there is a delay of less than `attestationWindowLength` blocks, the next window will still be scheduled the same as if there was no delay.
        attestationWindowLength = bound(attestationWindowLength, 1, DEFAULT_ATTESTATION_PERIOD - 1);
        rd.setAttestationWindowLength(attestationWindowLength);
        // attest to the current window, on the next attestation the new window will be scheduled after the new `attestationWindowLength` blocks
        attest();
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attestationDelay = bound(attestationDelay, 0, attestationWindowLength - 1);
        // attest to the next window
        uint256 attestationBlockNumber = block.number - 1;
        vm.roll(block.number + attestationDelay);
        assertStatus(attestationBlockNumber, IRewardDistributor.Status.Active, 'Window should become active');
        // vm.expectEmit();
        // emit IRewardDistributor.AttestationWindowScheduled(
        //     attestationBlockNumber, attestationBlockNumber + attestationWindowLength
        // );
        vm.recordLogs();
        attest(attestationBlockNumber);
        expectNotEmit(IRewardDistributor.AttestationWindowExtended.selector, 'Should not extend the attestation window');
    }

    function test_shouldInitializeWindowsCorrectlyAfterDelay(uint256 attestationWindowLength, uint256 attestationDelay)
        public
    {
        // Should the delay be larger than `attestationWindowLength`, it means that the next window is not scheduled automatically. In this case the current window will be extended until the next attestation occurs.
        attestationWindowLength = bound(attestationWindowLength, 1, DEFAULT_ATTESTATION_PERIOD - 1);
        rd.setAttestationWindowLength(attestationWindowLength);
        // attest to the current window, on the next attestation the new window will be scheduled after the new `attestationWindowLength` blocks
        attest();
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
        attest(attestationBlockNumber);
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

    function test_shouldFinalizeWindowWithMajorityVotes() public {
        uint256 baseRewardPerWindow = 10 ether;
        rd.setAttestationPeriod(DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attest(operator);
        attest(operator2);
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        // first window (block 0 - block.number - 1) doesn't have any rewards
        vm.expectEmit();
        emit IRewardDistributor.WindowFinalized(
            block.number - DEFAULT_ATTESTATION_WINDOW_LENGTH - 1, IRewardDistributor.AttestationResult.Valid, 1e18, 0
        );
        attest(operator);

        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        // second window now accumulates rewards, on finalization the rewards not claimable by non voting operators are allocated towards future windows
        vm.expectEmit();
        emit IRewardDistributor.RewardReceived(
            block.number - 1 + DEFAULT_ATTESTATION_WINDOW_LENGTH, baseRewardPerWindow * 33 / 100
        );
        vm.expectEmit();
        emit IRewardDistributor.WindowFinalized(
            block.number - DEFAULT_ATTESTATION_WINDOW_LENGTH - 1,
            IRewardDistributor.AttestationResult.Valid,
            67e16,
            baseRewardPerWindow * 67 / 100
        );
        attest(operator);
    }

    function test_shouldFinalizeWindowWithMinorityVotes() public {
        uint256 baseRewardPerWindow = 10 ether;
        rd.setAttestationPeriod(DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attest(operator);
        attest(operator2);
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        // first window (block 0 - block.number - 1) doesn't have any rewards
        vm.expectEmit();
        emit IRewardDistributor.WindowFinalized(
            block.number - DEFAULT_ATTESTATION_WINDOW_LENGTH - 1, IRewardDistributor.AttestationResult.Valid, 1e18, 0
        );
        attest(operator2);

        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        // second window now accumulates rewards, on finalization the rewards not claimable by non voting operators are allocated towards future windows
        vm.expectEmit();
        emit IRewardDistributor.RewardReceived(
            block.number - 1 + DEFAULT_ATTESTATION_WINDOW_LENGTH, baseRewardPerWindow * 67 / 100
        );
        vm.expectEmit();
        emit IRewardDistributor.WindowFinalized(
            block.number - DEFAULT_ATTESTATION_WINDOW_LENGTH - 1,
            IRewardDistributor.AttestationResult.InsufficientVotes,
            33e16,
            baseRewardPerWindow * 33 / 100
        );
        attest(operator2);
    }

    function test_shouldFinalizeWindowWithDifferingBlockHash() public {
        uint256 baseRewardPerWindow = 10 ether;
        rd.setAttestationPeriod(DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attest(operator);
        attest(operator2);
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        // first window (block 0 - block.number - 1) doesn't have any rewards
        vm.expectEmit();
        emit IRewardDistributor.WindowFinalized(
            block.number - DEFAULT_ATTESTATION_WINDOW_LENGTH - 1, IRewardDistributor.AttestationResult.Valid, 1e18, 0
        );
        attest(operator, block.number - 1, bytes32('invalid block hash'));

        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        // second window now accumulates rewards, on finalization the rewards not claimable by non voting operators are allocated towards future windows
        vm.expectEmit();
        emit IRewardDistributor.RewardReceived(
            block.number - 1 + DEFAULT_ATTESTATION_WINDOW_LENGTH, baseRewardPerWindow * 33 / 100
        );
        vm.expectEmit();
        emit IRewardDistributor.WindowFinalized(
            block.number - DEFAULT_ATTESTATION_WINDOW_LENGTH - 1,
            IRewardDistributor.AttestationResult.Invalid,
            67e16,
            baseRewardPerWindow * 67 / 100
        );
        attest(operator);
    }

    function test_shouldReturnCorrectAttestationResult() public {
        rd.setAttestationPeriod(DEFAULT_ATTESTATION_WINDOW_LENGTH);
        uint256 blockNumber = block.number - 1;
        assertAttestationResult(
            blockNumber + DEFAULT_ATTESTATION_PERIOD * 10,
            IRewardDistributor.AttestationResult.Pending,
            'Future windows should be pending'
        );
        assertAttestationResult(
            blockNumber, IRewardDistributor.AttestationResult.Pending, 'Current window should be pending'
        );
        attest(operator2);
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        assertAttestationResult(
            blockNumber,
            IRewardDistributor.AttestationResult.InsufficientVotes,
            'Should return insufficient votes if not enough votes are cast'
        );
        blockNumber = block.number - 1;
        assertAttestationResult(
            blockNumber, IRewardDistributor.AttestationResult.Pending, 'active windows with no votes should be pending'
        );
        attest(operator2);
        assertAttestationResult(
            blockNumber,
            IRewardDistributor.AttestationResult.Pending,
            'active windows with insufficient votes should also be pending'
        );
        attest(operator);
        assertAttestationResult(
            blockNumber,
            IRewardDistributor.AttestationResult.Valid,
            'and should become valid immediately after more than half of the votes are cast'
        );
        vm.roll(block.number + DEFAULT_ATTESTATION_WINDOW_LENGTH);
        attest(operator, block.number - 1, bytes32('invalid block hash'));
        assertAttestationResult(
            block.number - 1,
            IRewardDistributor.AttestationResult.Invalid,
            'invalid blocks should also be marked as invalid immediately after enough votes are cast'
        );
    }
}
