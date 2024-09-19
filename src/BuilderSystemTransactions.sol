// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Owned} from "solmate/auth/Owned.sol";

/// @title Builder System Transactions
contract BuilderSystemTransactions is Owned(msg.sender) {
    error Unauthorized();
    event BuilderAdded(address indexed builder);
    event BuilderRemoved(address indexed builder);
    event FlashblockIndexSet(uint8 flashblockIndex);

    mapping(address => bool) public builders;
    uint8 public flashblockIndex;

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

    /// @notice Sets the flashblock index
    /// @dev Only a builder can set the flashblock index
    /// @param _flashblockIndex The new flashblock index
    function setFlashblockIndex(uint8 _flashblockIndex) external onlyBuilder {
        flashblockIndex = _flashblockIndex;
        emit FlashblockIndexSet(_flashblockIndex);
    }

    /// @notice Gets the current flashblock index
    /// @return flashblockIndex The current flashblock index
    function getFlashblockIndex() external view returns (uint8) {
        return uint8(flashblockIndex);
    }

    /// @notice Gets the "Unichain Block" using the current block number and flashblock index
    /// @dev The Unichain Block that uniquely identifies the current block and flashblock
    ///   The top bit is flipped to indicate it is a Unichain Block
    ///   The block number is shifted by 8 bits to the left
    ///   The flashblock index is inserted in the last 8 bits
    /// @return unichainBlock The Unichain Block
    function getUnichainBlock() external view returns (uint256 unichainBlock) {
        // flip the top bit to indicate it is a unichain block
        unichainBlock |= 1 << 255;
        // insert the block number shifted by 8 bits
        unichainBlock |= block.number << 8;
        // insert the flashblock index and return
        return unichainBlock |= flashblockIndex;
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
