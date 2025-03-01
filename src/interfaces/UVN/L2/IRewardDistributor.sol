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

    /// @notice The result of the attestation for the given block number
    /// @dev Pending: The attestation period has not passed yet and no majority has voted for the block yet
    /// @dev InsufficientVotes: The attestation period has passed and no majority has voted for the block yet
    /// @dev Valid: a majority has voted for the block and the voted block hash matches the on chain block hash
    /// @dev Invalid: The attestation period has passed and a majority has voted for a different block
    enum AttestationResult {
        Pending,
        InsufficientVotes,
        Invalid,
        Valid
    }

    /// @notice Emitted when a window is scheduled
    event AttestationWindowScheduled(uint256 indexed currentWindowEnd, uint256 indexed scheduledNextWindowEnd);

    /// @notice Emitted when a window is extended due to a delay
    event AttestationWindowExtended(uint256 indexed originalWindowEnd, uint256 indexed newWindowEnd);

    /// @notice Emitted when an attestation is submitted
    event Attested(address indexed operator, uint256 indexed blockNumber, bytes32 votedHash);

    /// @notice Emitted when rewards are received
    event RewardReceived(uint256 indexed window, uint256 amount);

    /// @notice Emitted when a window is finalized
    /// @param blockNumber The block number of the last block in the window
    /// @param result The result of the attestation
    /// @param attestationRatio The ratio of stake that voted in relation to the total stake
    /// @param rewardsToDistribute The adjusted amount of rewards to distribute according to the attestation ratio
    event WindowFinalized(
        uint256 indexed blockNumber,
        AttestationResult indexed result,
        uint256 attestationRatio,
        uint256 rewardsToDistribute
    );

    /// @notice Thrown when the block is in the future
    error NoBlockHashAvailable();

    /// @notice Thrown when the attestation period has passed for a window
    error AttestationPeriodPassed();

    /// @notice Thrown when the window has already been finalized
    error WindowAlreadyFinalized();

    /// @notice Thrown when the operator has already attested to the block
    error BlockAlreadyAttested();

    /// @notice Thrown when the block number an operator is attesting to does not identify a window
    error WindowNotFound();

    /// @notice Thrown when the reward distribution to an operator fails
    error RewardDistributionFailed();

    /// @notice Thrown when the operator has 0 votes
    error ZeroVotes();

    /// @notice Attest to a window of blocks
    /// @dev The window is always identified by the block number of the last block in the window
    /// @dev The additional data has to match the data of other operators to be able to reach consensus
    /// @param blockNumber The block number of the last block in the window
    /// @param blockHash The block hash of the last block in the window
    /// @param additionalData Additional data to include in the attestation, e.g., information whether priority ordering was maintained in the block or the root of the next stake table
    /// @param signature The signature of the operator
    function attest(uint256 blockNumber, bytes32 blockHash, bytes memory additionalData, bytes memory signature)
        external;

    /// @notice Get the status of the window that contains the given block number
    /// @param targetBlockNumber The block number to check
    /// @return The status of the window containing the block number
    function status(uint256 targetBlockNumber) external view returns (Status);

    /// @notice Get the result of the attestation for the given block number
    /// @param targetBlockNumber The block number to check
    /// @return The result of the attestation
    function attestationResult(uint256 targetBlockNumber) external view returns (AttestationResult);

    /// @notice Get the latest active window that can be attested to
    /// @return blockNumber The block number of the last block in the latest active window
    function latestActiveWindow() external view returns (uint256 blockNumber);
}
