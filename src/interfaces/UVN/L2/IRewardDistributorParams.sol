// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRewardPuller} from './IRewardPuller.sol';

interface IRewardDistributorParams {
    /// @notice Emitted when the attestation window length is updated
    event AttestationWindowLengthUpdated(uint256 oldAttestationWindowLength, uint256 newAttestationWindowLength);
    /// @notice Emitted when the attestation period is updated
    event AttestationPeriodUpdated(uint256 oldAttestationPeriod, uint256 newAttestationPeriod);
    /// @notice Emitted when the reward puller contract is updated
    event RewardPullerUpdated(address oldRewardPuller, address newRewardPuller);

    error AmountZero();
    /// @notice Only the last 256 blockhashes are available, limiting the attestation window length to 256 blocks
    error AttestationWindowLengthTooLarge();
    /// @notice The attestation period must be at least as long as the attestation window length to ensure that active windows can always be attested to
    error AttestationPeriodTooShort();
    /// @notice The reward puller must implement the `IRewardPuller` interface
    error InvalidRewardPuller();

    /// @notice Update the attestation window length
    function setAttestationWindowLength(uint256 newAttestationWindowLength) external;
    /// @notice Update the attestation period
    function setAttestationPeriod(uint256 newAttestationPeriod) external;
    /// @notice Update the reward puller contract
    function setRewardPuller(IRewardPuller newRewardPuller) external;
    /// @notice The attestation window length determines the amount of blocks an operator is attesting to
    /// @dev Attestations are made to the last block of a given window
    function attestationWindowLength() external view returns (uint256);
    /// @notice The attestation period determines the amount of blocks an operator has to attest to an active window before it gets finalized
    function attestationPeriod() external view returns (uint256);
    /// @notice The reward puller contract is called whenever a new window is scheduled to fetch the rewards for the previous window
    /// @dev The reward puller contract must implement the `IRewardPuller` interface
    function rewardPuller() external view returns (IRewardPuller);
    /// @notice The role required to update the attestation window length, attestation period, and reward puller contract
    function PARAM_SETTER_ROLE() external view returns (bytes32);
}
