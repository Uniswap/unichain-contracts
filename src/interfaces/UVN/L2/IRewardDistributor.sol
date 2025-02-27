// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributorParams} from './IRewardDistributorParams.sol';

interface IRewardDistributor is IRewardDistributorParams {
    enum Status {
        NonExistent,
        Scheduled,
        Delayed,
        Active,
        Finalized
    }

    event AttestationWindowScheduled(uint256 indexed currentWindowEnd, uint256 indexed scheduledNextWindowEnd);
    event AttestationWindowExtended(uint256 indexed originalWindowEnd, uint256 indexed newWindowEnd);
    event Attested(address indexed operator, uint256 indexed blockNumber, bytes32 votedHash);
    event RewardReceived(uint256 indexed window, uint256 amount);

    error BlockAlreadyAttested();
    error NoBlockHashAvailable();
    error AttestationPeriodPassed();
    error InvalidSender();
    error WindowNotFound();
}
