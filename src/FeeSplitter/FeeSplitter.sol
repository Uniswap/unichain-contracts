// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';
import {SafeCall} from '@eth-optimism-bedrock/src/libraries/SafeCall.sol';

import {IFeeSplitter} from '../interfaces/FeeSplitter/IFeeSplitter.sol';
import {IFeeVault} from '../interfaces/optimism/IFeeVault.sol';

/// @title FeeSplitter
/// @dev Withdraws funds from system FeeVault contracts, shares revenue with Optimism, sends remaining revenue to L1 and net fee recipients
contract FeeSplitter is IFeeSplitter {
    // bytes32(uint256(keccak256('lock')) - 1);
    bytes32 private constant LOCK_STORAGE_SLOT = 0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e91;
    // bytes32(uint256(keccak256('net.revenue')) - 1);
    bytes32 private constant NET_REVENUE_STORAGE_SLOT =
        0x784be9e5da62c580888dd777e3d4e36ef68053ef5af2fc8f65c4050e4729e434;

    uint32 internal constant BASIS_POINT_SCALE = 1000;
    uint32 internal constant NET_REVENUE_SHARE = 150;
    uint32 internal constant GROSS_REVENUE_SHARE = 25;

    /// @dev The address of the Optimism wallet that will receive Optimism's revenue share.
    address public immutable OPTIMISM_WALLET;

    /// @dev The address of the Rewards Distributor that will receive a share of fees;
    address public immutable NET_FEE_RECIPIENT;

    /// @dev The address of the L1 wallet that will receive the OP chain runner's share of fees.
    address public immutable L1_FEE_RECIPIENT;

    /// @dev Constructor for the FeeSplitter contract which validates and sets immutable variables.
    /// @param optimismWallet The address which receives Optimism's revenue share.
    /// @param l1FeeRecipient The address which receives the L1 fee share.
    /// @param netFeeRecipient The address which receives the net fee share.
    constructor(address optimismWallet, address l1FeeRecipient, address netFeeRecipient) {
        if (optimismWallet == address(0) || netFeeRecipient == address(0) || l1FeeRecipient == address(0)) {
            revert AddressZero();
        }
        OPTIMISM_WALLET = optimismWallet;
        NET_FEE_RECIPIENT = netFeeRecipient;
        L1_FEE_RECIPIENT = l1FeeRecipient;
    }

    /// @inheritdoc IFeeSplitter
    function distributeFees() external virtual returns (bool feesDistributed) {
        if (
            Predeploys.SEQUENCER_FEE_WALLET.balance < IFeeVault(Predeploys.SEQUENCER_FEE_WALLET).minWithdrawalAmount()
                || Predeploys.BASE_FEE_VAULT.balance < IFeeVault(Predeploys.BASE_FEE_VAULT).minWithdrawalAmount()
                || Predeploys.L1_FEE_VAULT.balance < IFeeVault(Predeploys.L1_FEE_VAULT).minWithdrawalAmount()
        ) {
            // only collect fees if all fee vaults can be withdrawn from to guarantee accurate accounting of optimism revenue share
            emit NoFeesCollected();
            return false;
        }

        // unlock
        assembly ("memory-safe") {
            tstore(LOCK_STORAGE_SLOT, 1)
        }
        _feeVaultWithdrawal(Predeploys.SEQUENCER_FEE_WALLET);
        _feeVaultWithdrawal(Predeploys.BASE_FEE_VAULT);
        _feeVaultWithdrawal(Predeploys.L1_FEE_VAULT);

        uint256 netFeeRevenue;
        uint256 grossFeeRevenue = address(this).balance;

        assembly ("memory-safe") {
            netFeeRevenue := tload(NET_REVENUE_STORAGE_SLOT)
            tstore(NET_REVENUE_STORAGE_SLOT, 0)
        }

        uint256 netRevenueShare = netFeeRevenue * NET_REVENUE_SHARE / BASIS_POINT_SCALE;
        uint256 grossRevenueShare = grossFeeRevenue * GROSS_REVENUE_SHARE / BASIS_POINT_SCALE;

        uint256 optimismRevenueShare;
        uint256 l1Fee;
        uint256 remainingNetRevenue;
        if (grossRevenueShare > netRevenueShare) {
            // if the gross revenue share is greater than the net revenue share, 2.5% of the gross revenue is sent to optimism
            // the remaining 97.5% of the L1 fees are sent to L1
            // the remaining 97.5% of the net fees are sent to the net fee recipient
            optimismRevenueShare = grossRevenueShare;
            l1Fee = (grossFeeRevenue - netFeeRevenue) * (BASIS_POINT_SCALE - GROSS_REVENUE_SHARE) / BASIS_POINT_SCALE;
            remainingNetRevenue = netFeeRevenue * (BASIS_POINT_SCALE - GROSS_REVENUE_SHARE) / BASIS_POINT_SCALE;
        } else {
            // if the net revenue share is greater than the gross revenue share, 15% of the net revenue is sent to optimism
            // the entire amount of L1 fees are sent to L1
            // the remaining 85% of the net fees are sent to the net fee recipient
            optimismRevenueShare = netRevenueShare;
            l1Fee = grossFeeRevenue - netFeeRevenue;
            remainingNetRevenue = netFeeRevenue - optimismRevenueShare;
        }

        if (!SafeCall.send(OPTIMISM_WALLET, gasleft(), optimismRevenueShare)) revert TransferFailed();

        if (!SafeCall.send(L1_FEE_RECIPIENT, gasleft(), l1Fee)) revert TransferFailed();

        if (!SafeCall.send(NET_FEE_RECIPIENT, gasleft(), remainingNetRevenue)) revert TransferFailed();

        emit FeesDistributed(optimismRevenueShare, l1Fee, remainingNetRevenue);
        return true;
    }

    /// @dev Receives ETH fees withdrawn from L2 FeeVaults and stores the net revenue in transient storage.
    /// @dev Will revert if ETH is not sent from L2 FeeVaults.
    /// @dev anyone can call the withdraw function on the vaults, the lock ensures that a withdrawal is only successful if the fee splitter is withdrawing the fees to ensure accurate accounting
    receive() external payable virtual {
        uint256 unlocked;
        assembly ("memory-safe") {
            unlocked := tload(LOCK_STORAGE_SLOT)
        }
        if (unlocked == 0) revert Locked();

        // TODO: explore whether the withdraw function can return a value indicating the amount of fees withdrawn
        if (msg.sender == Predeploys.SEQUENCER_FEE_WALLET || msg.sender == Predeploys.BASE_FEE_VAULT) {
            uint256 amount = msg.value;
            // combine the fees from the sequencer and base FeeVaults as net revenue
            assembly ("memory-safe") {
                tstore(NET_REVENUE_STORAGE_SLOT, add(tload(NET_REVENUE_STORAGE_SLOT), amount))
            }
        } else if (msg.sender == Predeploys.L1_FEE_VAULT) {
            // L1 Fee can be retrieved by subtracting the net fee revenue from address(this).balance
            // any dust not distributed in previous distributions is allocated towards L1 fee revenue automatically
        } else {
            revert OnlyVaults();
        }
    }

    function _feeVaultWithdrawal(address _feeVault) internal {
        // TODO: is it sufficient to check that the fee vaults are configured properly once in the constructor?
        if (IFeeVault(_feeVault).withdrawalNetwork() != IFeeVault.WithdrawalNetwork.L2) {
            revert MustWithdrawToL2();
        }
        if (IFeeVault(_feeVault).recipient() != address(this)) {
            revert MustWithdrawToFeeSplitter();
        }
        IFeeVault(_feeVault).withdraw();
    }
}
