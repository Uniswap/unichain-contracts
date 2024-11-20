// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Owned} from 'solmate/auth/Owned.sol';

/// @title Builder System Transactions
contract BuilderSystemTransactions is Owned(msg.sender) {
    error Unauthorized();

    event BuilderAdded(address indexed builder);
    event BuilderRemoved(address indexed builder);
    event FlashblockIndexSet(uint8 flashblockIndex);

    mapping(address => bool) public builders;
    uint8 public lastFlashblockIndex;
    uint256 public lastBlockNumber;

    modifier onlyBuilder() {
        if (!builders[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address[] memory initialBuilders) {
        for (uint256 i = 0; i < initialBuilders.length; i++) {
            builders[initialBuilders[i]] = true;
        }
    }

    /// @notice Increments the flashblock index
    /// @dev Only a builder can set the flashblock index
    /// @dev The flashblock index is reset when a new block is reached
    function incrementFlashblockIndex() external onlyBuilder {
        uint8 _lastFlashblockIndex;
        if (block.number == lastBlockNumber) {
            // same block, increment flashblock index
            _lastFlashblockIndex = lastFlashblockIndex + 1;
        } else {
            // new block, reset flashblock index and update block number
            lastBlockNumber = block.number;
        }

        lastFlashblockIndex = _lastFlashblockIndex;
        emit FlashblockIndexSet(_lastFlashblockIndex);
    }

    /// @notice Gets the current flashblock index
    /// @return flashblockIndex The current flashblock index
    function getFlashblockIndex() external view returns (uint8) {
        return uint8(lastFlashblockIndex);
    }

    /// @notice Adds a builder to the list of builders
    /// @dev Only the owner can add a builder
    /// @param builder The address of the builder to add
    function addBuilder(address builder) external onlyOwner {
        builders[builder] = true;
        emit BuilderAdded(builder);
    }

    /// @notice Removes a builder from the list of builders
    /// @dev Only the owner can add a builder
    /// @param builder The address of the builder to remove
    function removeBuilder(address builder) external onlyOwner {
        builders[builder] = false;
        emit BuilderRemoved(builder);
    }
}
