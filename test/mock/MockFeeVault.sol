// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IFeeVault} from '../../src/interfaces/optimism/IFeeVault.sol';
import {SafeCall} from '@eth-optimism-bedrock/src/libraries/SafeCall.sol';

contract MockFeeVault is IFeeVault {
    uint256 public immutable MIN_WITHDRAWAL_AMOUNT;
    address public immutable RECIPIENT;
    IFeeVault.WithdrawalNetwork public immutable WITHDRAWAL_NETWORK;

    constructor(address _recipient, uint256 _minWithdrawalAmount, IFeeVault.WithdrawalNetwork _withdrawalNetwork) {
        RECIPIENT = _recipient;
        MIN_WITHDRAWAL_AMOUNT = _minWithdrawalAmount;
        WITHDRAWAL_NETWORK = _withdrawalNetwork;
    }

    /// @notice Allow the contract to receive ETH.
    receive() external payable {}

    function minWithdrawalAmount() public view returns (uint256 amount_) {
        amount_ = MIN_WITHDRAWAL_AMOUNT;
    }

    function recipient() public view returns (address recipient_) {
        recipient_ = RECIPIENT;
    }

    function withdrawalNetwork() public view returns (IFeeVault.WithdrawalNetwork network_) {
        network_ = WITHDRAWAL_NETWORK;
    }

    function withdraw() external {
        require(
            address(this).balance >= MIN_WITHDRAWAL_AMOUNT,
            'FeeVault: withdrawal amount must be greater than minimum withdrawal amount'
        );

        uint256 value = address(this).balance;

        bool success = SafeCall.send(RECIPIENT, value);
        require(success, 'FeeVault: failed to send ETH to L2 fee recipient');
    }
}
