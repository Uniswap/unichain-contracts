// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IOperatorFeeManager} from '../../../interfaces/UVN/L2/IOperatorFeeManager.sol';

/// @title OperatorFeeManager - Example implementation of the OperatorFeeManager
/// @notice This contract is called by the DefaultDelegatorClaim to calculate the operator fee for a given reward received by delegators. Arbitrary logic can be implemented to calculate the operator fee as well as the distribution of the fee to the operator.
contract ExampleOperatorFeeManager is IOperatorFeeManager {
    uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;

    address public immutable OPERATOR;
    uint256 public immutable OPERATOR_FEE;

    constructor(address operator, uint256 operatorFee_) {
        OPERATOR = operator;
        OPERATOR_FEE = operatorFee_;
    }

    /// @dev Handles the fees received from the DefaultDelegatorClaim
    /// @dev The operator can implement arbitrary logic to distribute the fees to themselves, e.g., send them to the operator address or a cold storage, send fees based on certain rules, e.g., if a threshold is reached or the operator balance is below a certain amount, etc.
    receive() external payable {
        (bool success,) = OPERATOR.call{value: msg.value}('');
        require(success);
    }

    /// @dev Calculates the operator fee for a given reward
    /// @dev Arbitrary logic to calculate the operator fee can be implemented here, e.g., a dynamic fee based on the current gas price, a tiered fee structure, etc.
    function operatorFee(uint256 reward) external view returns (uint256) {
        return (reward * OPERATOR_FEE) / PERCENTAGE_DENOMINATOR;
    }
}
