// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributorParams} from './IRewardDistributorParams.sol';

interface IRewardDistributor is IRewardDistributorParams {
    /// @notice Status of block numbers and windows
    /// @dev NonExistent: The block number/window is in the future and has not been scheduled
    /// @dev Pending: The block number/window is in the future and will become scheduled after the next attestation to the current window
    /// @dev Scheduled: The block number/window is in the future and has been scheduled to be attested
    /// @dev Delayed: The currently active window has not received any attestations yet and thus the scheduled window is delayed
    /// @dev Active: The currently active window that is receiving attestations
    /// @dev Finalized: A window has been attested and the attestation period has passed
    enum Status {
        NonExistent,
        Pending,
        Scheduled,
        Delayed,
        Active,
        Finalized
    }

    /// @notice Emitted when a window is scheduled
    event AttestationWindowScheduled(uint256 indexed currentWindowEnd, uint256 indexed scheduledNextWindowEnd);
    /// @notice Emitted when a window is extended due to a delay
    event AttestationWindowExtended(uint256 indexed originalWindowEnd, uint256 indexed newWindowEnd);
    /// @notice Emitted when an attestation is submitted
    event Attested(address indexed operator, uint256 indexed blockNumber, bytes32 votedHash);
    /// @notice Emitted when rewards are received
    event RewardReceived(uint256 indexed window, uint256 amount);

    error BlockAlreadyAttested();
    error NoBlockHashAvailable();
    error AttestationPeriodPassed();
    error InvalidSender();
    error WindowNotFound();

    /// @notice Attest to a window of blocks
    /// @dev The window is always identified by the block number of the last block in the window
    /// @dev The additional data has to match the data of other operators to be able to reach consensus
    /// @param blockNumber The block number of the last block in the window
    /// @param blockHash The block hash of the last block in the window
    /// @param additionalData Additional data to include in the attestation
    /// @param signature The signature of the operator
    function attest(uint256 blockNumber, bytes32 blockHash, bytes memory additionalData, bytes memory signature)
        external;

    /// @notice Get the status of the window that contains the given block number
    /// @param targetBlockNumber The block number to check
    /// @return The status of the window containing the block number
    function status(uint256 targetBlockNumber) external view returns (Status);

    /// @notice Get the latest active window that can be attested to
    /// @return blockNumber The block number of the last block in the latest active window
    function latestActiveWindow() external view returns (uint256 blockNumber);
}
