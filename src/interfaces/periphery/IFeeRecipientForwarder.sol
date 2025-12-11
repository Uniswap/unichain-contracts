// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IFeeRecipientForwarder
/// @notice Interface for the FeeRecipientForwarder contract
interface IFeeRecipientForwarder {
    /// @notice Withdraws fees from the NetFeeSplitter and sends them to the recipient
    /// @return amount The amount of fees withdrawn
    function withdraw() external returns (uint256 amount);
}
