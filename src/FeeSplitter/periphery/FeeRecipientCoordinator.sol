// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IFeeRecipientForwarder} from '../../interfaces/periphery/IFeeRecipientForwarder.sol';

/// @title FeeRecipientCoordinator
/// @notice A helper contract to withdraw fees from multiple FeeRecipientForwarders in one transaction
contract FeeRecipientCoordinator {
    IFeeRecipientForwarder[] private feeRecipientForwarders;

    constructor(IFeeRecipientForwarder[] memory _feeRecipientForwarders) {
        feeRecipientForwarders = _feeRecipientForwarders;
    }

    /// @notice Withdraws fees from all FeeRecipientForwarders
    /// @dev This function will fail if any of the inner withdrawals revert
    /// @return totalAmount The total amount of fees withdrawn
    function withdraw() external returns (uint256 totalAmount) {
        for (uint256 i = 0; i < feeRecipientForwarders.length; i++) {
            totalAmount += feeRecipientForwarders[i].withdraw();
        }
        return totalAmount;
    }
}
