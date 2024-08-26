// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {L2StakeManager} from './L2StakeManager.sol';

import {console2} from 'forge-std/console2.sol';
import {FixedPointMathLib} from 'solmate/utils/FixedPointMathLib.sol';

contract RewardDistributor {
    using FixedPointMathLib for uint256;
    /// @dev The number of blocks attesters have to vote on a block

    uint256 public constant ATTESTATION_PERIOD = 10;

    /// @dev The address of the payment splitter contract that receives sequencer rewards.
    address private immutable PAYMENT_SPLITTER;
    L2StakeManager private immutable L2_STAKE_MANAGER;

    struct Block {
        uint256 reward;
        bytes32 blockHash;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct Reward {
        uint256 earned;
        uint256 head;
        uint256 tail;
        mapping(uint256 blockNumber => uint256 next) next;
    }

    mapping(uint256 blockNumber => Block) private _blocks;
    mapping(address user => Reward) private _rewards;
    mapping(address validator => uint256) private _inactiveUntil;

    event RewardDeposited(uint256 indexed blockNumber, uint256 reward);
    event Attested(uint256 indexed blockNumber, address indexed user, bytes32 blockHash, bool vote);
    event Finalized(uint256 indexed blockNumber, address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    error Unauthorized();
    error InvalidBlockNumber();
    error InvalidBlockHash();
    error AttestationPeriodExpired();
    error AttestationOutOfOrder();
    error TransferFailed();

    constructor(address paymentSplitter, address l2StakeManager) {
        PAYMENT_SPLITTER = paymentSplitter;
        L2_STAKE_MANAGER = L2StakeManager(l2StakeManager);
    }

    /// @dev Receives rewards from the payment splitter contract for the current block.
    /// @dev Stores the block hash of the previous block.
    receive() external payable {
        if (msg.sender != PAYMENT_SPLITTER) {
            revert Unauthorized();
        }
        uint256 currentBlock = block.number;
        _blocks[currentBlock].reward += msg.value;
        _blocks[currentBlock - 1].blockHash = blockhash(currentBlock - 1);
        emit RewardDeposited(currentBlock, msg.value);
    }

    function attest(uint256 blockNumber, bytes32 blockHash, bool vote) external {
        _finalizeNext(msg.sender);
        // subtract 2 because hash will be available after n + 1 blocks
        if (blockNumber > block.number - 2) revert InvalidBlockNumber();
        if (isFinalized(blockNumber)) revert AttestationPeriodExpired();
        if (blockNumber <= _rewards[msg.sender].tail) revert AttestationOutOfOrder();
        // in case of a reorg the attestation will fail
        if (blockHash != _blocks[blockNumber].blockHash) revert InvalidBlockHash();
        uint256 balance = L2_STAKE_MANAGER.getPastVotes(msg.sender, blockNumber);
        if (vote) {
            _blocks[blockNumber].votesFor += balance;
        } else {
            _blocks[blockNumber].votesAgainst += balance;
        }
        _rewards[msg.sender].next[_rewards[msg.sender].tail] = _encodeNext(blockNumber, vote);
        _rewards[msg.sender].tail = blockNumber;
        emit Attested(blockNumber, msg.sender, blockHash, vote);
    }

    function withdraw(address recipient) external {
        uint256 amount = _rewards[recipient].earned;
        _rewards[recipient].earned = 0;
        (bool success,) = recipient.call{value: amount}('');
        if (!success) revert TransferFailed();
        emit Withdrawn(recipient, amount);
    }

    function finalize(address account, uint256 n) external {
        for (uint256 i = 0; i < n; i++) {
            _finalizeNext(account);
        }
    }

    function isFinalized(uint256 blockNumber) public view returns (bool) {
        return blockNumber < block.number - ATTESTATION_PERIOD - 2;
    }

    function earned(address account) public view returns (uint256) {
        return _rewards[account].earned;
    }

    /// @notice Finalizes the rewards for the next block for account
    /// if account is delegated to another account, the rewards are calculated pro-rate based on the balance of the delegator over the total votes held by the delegatee
    function _finalizeNext(address account) internal {
        address delegatee = L2_STAKE_MANAGER.delegates(account);
        uint256 head = _rewards[delegatee].head;
        if (!isFinalized(head)) return;
        (uint256 next, bool vote) = _decodeNext(_rewards[delegatee].next[head]);
        if (next == 0) return;
        uint256 votes;
        if (!vote) {
            uint256 votesAgainst = _blocks[next].votesAgainst;
            bool isInvalid = votesAgainst * 3 / 2 > L2_STAKE_MANAGER.getPastTotalSupply(next); // TODO: precision loss here?
            if (isInvalid) {
                votes = votesAgainst;
            }
        } else {
            votes = _blocks[next].votesFor;
        }

        uint256 reward;
        if (votes != 0) {
            // get the reward for the delegatee
            uint256 delegateeVotes = L2_STAKE_MANAGER.getPastVotes(delegatee, next);
            reward = _blocks[next].reward.mulDivDown(delegateeVotes, votes);
            // get the pro-rate reward for the account if not self-delegated
            if (account != delegatee) {
                reward = reward.mulDivDown(
                    L2_STAKE_MANAGER.getPastBalance(account, next), delegateeVotes
                );
            }
        }
        _rewards[account].earned += reward;
        _rewards[account].head = next;
        emit Finalized(next, account, reward);
    }

    function _encodeNext(uint256 blockNumber, bool vote) private pure returns (uint256) {
        return (blockNumber << 1) | (vote ? 1 : 0);
    }

    function _decodeNext(uint256 next) private pure returns (uint256 blockNumber, bool vote) {
        return (next >> 1, next & 1 == 1);
    }
}
