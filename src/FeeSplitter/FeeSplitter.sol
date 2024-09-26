// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';
import {SafeCall} from '@eth-optimism-bedrock/src/libraries/SafeCall.sol';

import {IFeeSplitter} from '../interfaces/FeeSplitter/IFeeSplitter.sol';
import {IFeeVault} from '../interfaces/optimism/IFeeVault.sol';
import {IL2StandardBridge} from '../interfaces/optimism/IL2StandardBridge.sol';

/**
 * @title FeeSplitter
 * @dev Withdraws funds from system FeeVault contracts, shares revenue with Optimism, sends revenue to L1 and net fee splitters
 */
contract FeeSplitter is IFeeSplitter {
    // bytes32(uint256(keccak256('net.revenue')) - 1);
    bytes32 private constant NET_REVENUE_STORAGE_SLOT =
        0x784be9e5da62c580888dd777e3d4e36ef68053ef5af2fc8f65c4050e4729e434;

    uint32 internal constant BASIS_POINT_SCALE = 1000;
    uint32 internal constant NET_REVENUE_SHARE = 150;
    uint32 internal constant GROSS_REVENUE_SHARE = 25;

    /// @dev The address of the Optimism wallet that will receive Optimism's revenue share.
    address internal immutable OPTIMISM_WALLET;

    /// @dev The address of the Rewards Distributor that will receive a share of fees;
    address internal immutable NET_FEE_SPLITTER;

    /// @dev The address of the L1 wallet that will receive the OP chain runner's share of fees.
    address internal immutable L1_FEE_SPLITTER;

    /// @dev Constructor for the FeeSplitter contract which validates and sets immutable variables.
    /// @param optimismWallet_ The address which receives Optimism's revenue share.
    /// @param l1FeeSplitter_ The address which receives the L1 fee share.
    /// @param netFeeSplitter_ The address which receives the net fee share.
    constructor(address optimismWallet_, address l1FeeSplitter_, address netFeeSplitter_) {
        if (optimismWallet_ == address(0) || netFeeSplitter_ == address(0) || l1FeeSplitter_ == address(0)) {
            revert AmountZero();
        }
        OPTIMISM_WALLET = optimismWallet_;
        NET_FEE_SPLITTER = netFeeSplitter_;
        L1_FEE_SPLITTER = l1FeeSplitter_;
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
        feeVaultWithdrawal(Predeploys.SEQUENCER_FEE_WALLET);
        feeVaultWithdrawal(Predeploys.BASE_FEE_VAULT);
        feeVaultWithdrawal(Predeploys.L1_FEE_VAULT);

        uint256 netFeeRevenue;
        uint256 grossFeeRevenue = address(this).balance;

        assembly ("memory-safe") {
            netFeeRevenue := tload(NET_REVENUE_STORAGE_SLOT)
            tstore(NET_REVENUE_STORAGE_SLOT, 0)
        }

        uint256 netRevenueShare = netFeeRevenue * NET_REVENUE_SHARE / BASIS_POINT_SCALE;
        uint256 grossRevenueShare = grossFeeRevenue * GROSS_REVENUE_SHARE / BASIS_POINT_SCALE;

        uint256 optimismRevenueShare;
        uint256 l1Fee = grossFeeRevenue - netFeeRevenue;
        uint256 remainingNetRevenue = netFeeRevenue;
        if (grossRevenueShare > netRevenueShare) {
            optimismRevenueShare = grossRevenueShare;
            l1Fee = l1Fee * (BASIS_POINT_SCALE - GROSS_REVENUE_SHARE) / BASIS_POINT_SCALE;
            remainingNetRevenue = netFeeRevenue * (BASIS_POINT_SCALE - GROSS_REVENUE_SHARE) / BASIS_POINT_SCALE;
        } else {
            optimismRevenueShare = netRevenueShare;
            remainingNetRevenue -= optimismRevenueShare;
        }

        if (!SafeCall.send(OPTIMISM_WALLET, gasleft(), optimismRevenueShare)) revert TransferFailed();

        if (!SafeCall.send(L1_FEE_SPLITTER, gasleft(), l1Fee)) revert TransferFailed();

        if (!SafeCall.send(NET_FEE_SPLITTER, gasleft(), remainingNetRevenue)) revert TransferFailed();

        emit FeesDistributed(optimismRevenueShare, l1Fee, remainingNetRevenue);
        return true;
    }

    /// @dev Receives ETH fees withdrawn from L2 FeeVaults and stores the net revenue in transient storage.
    /// @dev Will revert if ETH is not sent from L2 FeeVaults.
    receive() external payable virtual {
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

    function feeVaultWithdrawal(address _feeVault) internal {
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
