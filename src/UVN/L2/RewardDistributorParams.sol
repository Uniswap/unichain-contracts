// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributorParams} from '../../interfaces/UVN/L2/IRewardDistributorParams.sol';
import {IRewardPuller} from '../../interfaces/UVN/L2/IRewardPuller.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

contract RewardDistributorParams is AccessControl, IRewardDistributorParams {
    bytes32 public constant PARAM_SETTER_ROLE = keccak256('PARAM_SETTER_ROLE');

    uint256 private _attestationWindowLength;
    uint256 private _attestationPeriod;
    IRewardPuller private _rewardPuller;

    constructor(
        address admin,
        uint256 attestationWindowLength_,
        uint256 attestationPeriod_,
        IRewardPuller rewardPuller_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _setAttestationWindowLength(attestationWindowLength_);
        _setAttestationPeriod(attestationPeriod_);
        _setRewardPuller(rewardPuller_);
    }

    function setAttestationWindowLength(uint256 newAttestationWindowLength) external onlyRole(PARAM_SETTER_ROLE) {
        _setAttestationWindowLength(newAttestationWindowLength);
    }

    function setAttestationPeriod(uint256 newAttestationPeriod) external onlyRole(PARAM_SETTER_ROLE) {
        _setAttestationPeriod(newAttestationPeriod);
    }

    function setRewardPuller(IRewardPuller newRewardPuller) external onlyRole(PARAM_SETTER_ROLE) {
        _setRewardPuller(newRewardPuller);
    }

    function attestationWindowLength() public view returns (uint256) {
        return _attestationWindowLength;
    }

    function attestationPeriod() public view returns (uint256) {
        return _attestationPeriod;
    }

    function rewardPuller() public view returns (IRewardPuller) {
        return _rewardPuller;
    }

    function _setAttestationWindowLength(uint256 newAttestationWindowLength) internal {
        if (newAttestationWindowLength == 0) revert AmountZero();
        // Only the last 256 blockhashes are available, limiting the attestation window length to 256 blocks
        if (newAttestationWindowLength > 256) revert AttestationWindowLengthTooLarge();
        uint256 oldAttestationWindowLength = _attestationWindowLength;
        _attestationWindowLength = newAttestationWindowLength;
        emit AttestationWindowLengthUpdated(oldAttestationWindowLength, newAttestationWindowLength);
    }

    function _setAttestationPeriod(uint256 newAttestationPeriod) internal {
        if (newAttestationPeriod == 0) revert AmountZero();
        uint256 oldAttestationPeriod = _attestationPeriod;
        _attestationPeriod = newAttestationPeriod;
        emit AttestationPeriodUpdated(oldAttestationPeriod, newAttestationPeriod);
    }

    function _setRewardPuller(IRewardPuller newRewardPuller) internal {
        if (!newRewardPuller.supportsInterface(type(IRewardPuller).interfaceId)) revert InvalidRewardPuller();
        IRewardPuller oldRewardPuller = _rewardPuller;
        _rewardPuller = newRewardPuller;
        emit RewardPullerUpdated(address(oldRewardPuller), address(newRewardPuller));
    }
}
