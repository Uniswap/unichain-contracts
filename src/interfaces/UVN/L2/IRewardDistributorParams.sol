// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IRewardDistributorParams {
    event AttestationWindowLengthUpdated(uint256 oldAttestationWindowLength, uint256 newAttestationWindowLength);
    event AttestationPeriodUpdated(uint256 oldAttestationPeriod, uint256 newAttestationPeriod);

    error AmountZero();
    error AttestationWindowLengthTooLarge();

    // TODO: cannot exceed 256 blocks otherwise it's not possible to get the block hash
    function setAttestationWindowLength(uint256 newAttestationWindowLength) external;
    function setAttestationPeriod(uint256 newAttestationPeriod) external;
    function attestationWindowLength() external view returns (uint256);
    function attestationPeriod() external view returns (uint256);
    function PARAM_SETTER_ROLE() external view returns (bytes32);
}
