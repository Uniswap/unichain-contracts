// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {FeeSplitter, IFeeSplitter} from '../../src/FeeSplitter/FeeSplitter.sol';
import {IFeeVault, MockFeeVault} from '../mock/MockFeeVault.sol';
import {Predeploys} from '@eth-optimism-bedrock/src/libraries/Predeploys.sol';

contract FeeSplitterTest is Test {
    FeeVaultHelper internal helper;
    address opWallet = makeAddr('opWallet');
    address l1Splitter = makeAddr('l1Splitter');
    address netSplitter = makeAddr('netSplitter');

    FeeSplitter internal feeSplitter;

    function setUp() public {
        helper = new FeeVaultHelper();
        feeSplitter = new FeeSplitter(opWallet, l1Splitter, netSplitter);
        helper.deploy(feeSplitter, Predeploys.SEQUENCER_FEE_WALLET);
        helper.deploy(feeSplitter, Predeploys.BASE_FEE_VAULT);
        helper.deploy(feeSplitter, Predeploys.L1_FEE_VAULT);
    }

    function test_RevertIf_ConstructorAddressZero() public {
        vm.expectRevert(abi.encodeWithSelector(IFeeSplitter.AddressZero.selector));
        new FeeSplitter(address(0), address(1), address(1));
        vm.expectRevert(abi.encodeWithSelector(IFeeSplitter.AddressZero.selector));
        new FeeSplitter(address(1), address(0), address(1));
        vm.expectRevert(abi.encodeWithSelector(IFeeSplitter.AddressZero.selector));
        new FeeSplitter(address(1), address(1), address(0));
    }

    function test_RevertIf_FeesDepositedFromNonVault(address sender) public {
        vm.assume(sender != Predeploys.SEQUENCER_FEE_WALLET);
        vm.assume(sender != Predeploys.BASE_FEE_VAULT);
        vm.assume(sender != Predeploys.L1_FEE_VAULT);
        vm.prank(sender);
        (bool success, bytes memory revertData) = address(feeSplitter).call{value: 0}('');
        assertFalse(success, 'Did not revert');
        assertEq(
            revertData, abi.encodeWithSelector(IFeeSplitter.OnlyVaults.selector), 'Did not revert with `OnlyVaults()`'
        );
    }

    function test_ShouldBeAbleToDepositFeesFromL2FeeVaults() public {
        vm.prank(Predeploys.SEQUENCER_FEE_WALLET);
        (bool success,) = address(feeSplitter).call{value: 0}('');
        assertTrue(success);
        vm.prank(Predeploys.BASE_FEE_VAULT);
        (success,) = address(feeSplitter).call{value: 0}('');
        assertTrue(success);
        vm.prank(Predeploys.L1_FEE_VAULT);
        (success,) = address(feeSplitter).call{value: 0}('');
        assertTrue(success);
    }

    function test_RevertIf_WithdrawalNetworkIsL1(uint256 index) public {
        index = bound(index, 0, 2);
        if (index == 0) {
            helper.deployWithL1WithdrawalNetwork(feeSplitter, Predeploys.SEQUENCER_FEE_WALLET);
        } else if (index == 1) {
            helper.deployWithL1WithdrawalNetwork(feeSplitter, Predeploys.BASE_FEE_VAULT);
        } else {
            helper.deployWithL1WithdrawalNetwork(feeSplitter, Predeploys.L1_FEE_VAULT);
        }
        vm.expectRevert(abi.encodeWithSelector(IFeeSplitter.MustWithdrawToL2.selector));
        feeSplitter.distributeFees();
    }

    function test_RevertIf_WithdrawalRecipientIsNotFeeSplitter(uint256 index) public {
        index = bound(index, 0, 2);
        if (index == 0) {
            helper.deploy(FeeSplitter(payable(address(0))), Predeploys.SEQUENCER_FEE_WALLET);
        } else if (index == 1) {
            helper.deploy(FeeSplitter(payable(address(0))), Predeploys.BASE_FEE_VAULT);
        } else {
            helper.deploy(FeeSplitter(payable(address(0))), Predeploys.L1_FEE_VAULT);
        }
        vm.expectRevert(abi.encodeWithSelector(IFeeSplitter.MustWithdrawToFeeSplitter.selector));
        feeSplitter.distributeFees();
    }

    function test_ShouldNotDistributeFeesIfAnyVaultIsBelowMinWithdrawalAmount(
        uint256 index,
        uint256 minWithdrawalAmount
    ) public {
        index = bound(index, 0, 2);
        vm.assume(minWithdrawalAmount > 0);
        if (index == 0) {
            helper.deploy(feeSplitter, Predeploys.SEQUENCER_FEE_WALLET, minWithdrawalAmount);
        } else if (index == 1) {
            helper.deploy(feeSplitter, Predeploys.BASE_FEE_VAULT, minWithdrawalAmount);
        } else {
            helper.deploy(feeSplitter, Predeploys.L1_FEE_VAULT, minWithdrawalAmount);
        }
        vm.expectEmit(true, true, false, true);
        emit IFeeSplitter.NoFeesCollected();
        bool feesDistributed = feeSplitter.distributeFees();
        assertFalse(feesDistributed, 'Fees were distributed');
    }

    function test_ShouldDistributeNetRevenueShareIfLessThanGrossRevenueShare(
        uint256 sequencerFee,
        uint256 baseFee,
        uint256 l1Fee
    ) public {
        sequencerFee = bound(sequencerFee, 1, 100 ether);
        baseFee = bound(baseFee, 1, 100 ether);
        l1Fee = bound(l1Fee, 1, (sequencerFee + baseFee) * 150 / 25 - sequencerFee - baseFee);

        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, sequencerFee);
        vm.deal(Predeploys.BASE_FEE_VAULT, baseFee);
        vm.deal(Predeploys.L1_FEE_VAULT, l1Fee);

        uint256 expectedOpShare = (sequencerFee + baseFee) * 150 / 1000;
        uint256 expectedNetRevenueShare = (sequencerFee + baseFee) - expectedOpShare;
        uint256 expectedL1Share = l1Fee;

        vm.expectEmit(true, true, false, true);
        emit IFeeSplitter.FeesDistributed(expectedOpShare, expectedL1Share, expectedNetRevenueShare);
        bool feesDistributed = feeSplitter.distributeFees();
        assertTrue(feesDistributed, 'Fees were not distributed');
        assertEq(opWallet.balance, expectedOpShare, 'Op wallet balance is not expected');
        assertEq(l1Splitter.balance, expectedL1Share, 'L1 splitter balance is not expected');
        assertEq(netSplitter.balance, expectedNetRevenueShare, 'Net splitter balance is not expected');
    }

    function test_ShouldDistributeGrossRevenueShareIfMoreThanNetRevenueShare(
        uint256 sequencerFee,
        uint256 baseFee,
        uint256 l1Fee
    ) public {
        sequencerFee = bound(sequencerFee, 1, 100 ether);
        baseFee = bound(baseFee, 1, 100 ether);
        l1Fee = bound(l1Fee, (sequencerFee + baseFee) * 150 / 25 - sequencerFee - baseFee + 1, 10_000 ether);

        uint256 netRevenueShare = (sequencerFee + baseFee) * 150 / 1000;
        uint256 grossRevenueShare = (sequencerFee + baseFee + l1Fee) * 25 / 1000;
        vm.assume(grossRevenueShare > netRevenueShare);

        vm.deal(Predeploys.SEQUENCER_FEE_WALLET, sequencerFee);
        vm.deal(Predeploys.BASE_FEE_VAULT, baseFee);
        vm.deal(Predeploys.L1_FEE_VAULT, l1Fee);

        uint256 expectedOpShare = (sequencerFee + baseFee + l1Fee) * 25 / 1000;
        uint256 expectedNetRevenueShare = (sequencerFee + baseFee) * 975 / 1000;
        uint256 expectedL1Share = l1Fee * 975 / 1000;

        vm.expectEmit(true, true, false, true);
        emit IFeeSplitter.FeesDistributed(expectedOpShare, expectedL1Share, expectedNetRevenueShare);
        bool feesDistributed = feeSplitter.distributeFees();
        assertTrue(feesDistributed, 'Fees were not distributed');
        assertEq(opWallet.balance, expectedOpShare, 'Op wallet balance is not expected');
        assertEq(l1Splitter.balance, expectedL1Share, 'L1 splitter balance is not expected');
        assertEq(netSplitter.balance, expectedNetRevenueShare, 'Net splitter balance is not expected');
    }
}

contract FeeVaultHelper is Test {
    uint256 internal constant DEFAULT_MIN_WITHDRAWAL_AMOUNT = 0;
    IFeeVault.WithdrawalNetwork internal constant DEFAULT_WITHDRAWAL_NETWORK = IFeeVault.WithdrawalNetwork.L2;

    function deploy(FeeSplitter feeSplitter, address target) external {
        MockFeeVault feeVault =
            new MockFeeVault(address(feeSplitter), DEFAULT_MIN_WITHDRAWAL_AMOUNT, DEFAULT_WITHDRAWAL_NETWORK);
        vm.etch(target, address(feeVault).code);
    }

    function deploy(FeeSplitter feeSplitter, address target, uint256 minWithdrawalAmount) external {
        MockFeeVault feeVault = new MockFeeVault(address(feeSplitter), minWithdrawalAmount, DEFAULT_WITHDRAWAL_NETWORK);
        vm.etch(target, address(feeVault).code);
    }

    function deployWithL1WithdrawalNetwork(FeeSplitter feeSplitter, address target) external {
        MockFeeVault feeVault =
            new MockFeeVault(address(feeSplitter), DEFAULT_MIN_WITHDRAWAL_AMOUNT, IFeeVault.WithdrawalNetwork.L1);
        vm.etch(target, address(feeVault).code);
    }
}
