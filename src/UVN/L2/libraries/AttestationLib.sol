// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRewardDistributor} from '../../../interfaces/UVN/L2/IRewardDistributor.sol';

struct Attestation {
    bytes32 votedHash;
    uint256 votes;
    uint256 next;
}

struct Attestations {
    uint256 head;
    uint256 tail;
    mapping(uint256 blockNumber => Attestation) attestations;
}

using AttestationLib for Attestations global;

/// @notice A linked list of attestations for an operator
library AttestationLib {
    /// @notice Add an attestation to the linked list
    function push(Attestations storage $, uint256 blockNumber, bytes32 votedHash, uint256 votes) internal {
        // uh oh I hope you aren't double signing
        if ($.attestations[blockNumber].votedHash != bytes32(0)) revert IRewardDistributor.BlockAlreadyAttested();
        $.attestations[blockNumber] = Attestation({votedHash: votedHash, votes: votes, next: 0});
        $.attestations[$.tail].next = blockNumber;
        $.tail = blockNumber;
    }

    /// @notice Get the next block number an operator has attested to
    function nextBlockNumber(Attestations storage $) internal returns (uint256 blockNumber) {
        uint256 head = $.head;
        if (head == 0) {
            // initialize the linked list for a new operator
            // @audit tail is guaranteed to be set when the first attestation is pushed
            uint256 tail = $.tail;
            $.head = tail;
            return tail;
        }
        return head;
    }

    /// @notice Get the votes and voted hash for a given block number
    function getVotes(Attestations storage $, uint256 blockNumber)
        internal
        view
        returns (uint256 votes, bytes32 votedHash)
    {
        Attestation storage attestation = $.attestations[blockNumber];
        return (attestation.votes, attestation.votedHash);
    }

    /// @notice Called when the reward for this window is distributed
    /// @notice Must be called in order
    function finalize(Attestations storage $, uint256 blockNumber) internal {
        assert($.head == blockNumber);
        $.head = $.attestations[blockNumber].next;
    }
}
