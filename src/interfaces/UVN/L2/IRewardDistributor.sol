// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributorParams} from './IRewardDistributorParams.sol';

interface IRewardDistributor is IRewardDistributorParams {
    event AttestationWindowScheduled(
        uint256 indexed currentWindowEnd, uint256 indexed scheduledNextWindowEnd, uint256 reward
    );
    event AttestationWindowExtended(uint256 indexed originalWindowEnd, uint256 indexed newWindowEnd);
    event Attested(address indexed operator, uint256 indexed blockNumber, bytes32 votedHash);

    error BlockAlreadyAttested();
    error NoBlockHashAvailable();
    error AttestationPeriodPassed();
    error InvalidSender();
    error NoRewardsAvailable();
    error WindowNotFound();
}
