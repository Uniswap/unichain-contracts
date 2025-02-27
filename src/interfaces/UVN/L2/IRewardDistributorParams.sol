// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardPuller} from './IRewardPuller.sol';

interface IRewardDistributorParams {
    event AttestationWindowLengthUpdated(uint256 oldAttestationWindowLength, uint256 newAttestationWindowLength);
    event AttestationPeriodUpdated(uint256 oldAttestationPeriod, uint256 newAttestationPeriod);
    event RewardPullerUpdated(address oldRewardPuller, address newRewardPuller);

    error AmountZero();
    error AttestationWindowLengthTooLarge();
    error InvalidRewardPuller();

    function setAttestationWindowLength(uint256 newAttestationWindowLength) external;
    function setAttestationPeriod(uint256 newAttestationPeriod) external;
    function setRewardPuller(IRewardPuller newRewardPuller) external;
    function attestationWindowLength() external view returns (uint256);
    function attestationPeriod() external view returns (uint256);
    function rewardPuller() external view returns (IRewardPuller);
    function PARAM_SETTER_ROLE() external view returns (bytes32);
}
