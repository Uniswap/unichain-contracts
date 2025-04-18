// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IService, IStakeTableSync, StakeTableSync} from '../../../src/UVN/L1/StakeTableSync.sol';
import {IBaseService} from '../../../src/interfaces/UVN/IBaseService.sol';
import {L1TestHandler} from './L1TestHandler.sol';
import {IOptimismPortal2} from '@eth-optimism-bedrock/src/L1/interfaces/IOptimismPortal2.sol';
import {AddressAliasHelper} from '@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {console2} from 'forge-std/console2.sol';

contract StakeTableSyncTest is L1TestHandler {
    uint256 private constant DEFAULT_AMOUNT = 1000;
    // TODO adjust gas limits after measuring
    uint64 private constant DEFAULT_GAS_LIMIT = 200_000;
    uint64 private constant DEPLOY_GAS_LIMIT = 1_000_000;

    // Optimism event arguments
    uint256 private constant MINT_VALUE = 0;
    uint256 private constant VALUE = 0;
    uint256 private constant VERSION = 0;
    bool private constant IS_CREATION = false;

    StakeTableSync stakeTableSync;
    address l2StakeTable = makeAddr('l2StakeTable');
    bool forked;

    function setUp() public override {
        super.setUp();
        stakeTableSync = new StakeTableSync(stakingMiddleware, l2StakeTable);
        try vm.envString('INFURA_API_KEY') returns (string memory infuraKey) {
            string memory rpcUrl = string.concat('https://mainnet.infura.io/v3/', infuraKey);
            vm.createSelectFork(rpcUrl, 21_117_000);
            forked = true;
            console2.log('Forked Ethereum mainnet');
        } catch {
            console2.log(
                'Skipping forked tests, no infura key found. Add INFURA_API_KEY env var to .env to run forked tests.'
            );
        }
    }

    modifier onlyForked() {
        if (forked) {
            console2.log('running forked test');
            _;
            return;
        }
        console2.log('skipping forked test');
    }

    function toAlias(address l1Address) internal pure returns (address l2Address) {
        return AddressAliasHelper.applyL1ToL2Alias(l1Address);
    }

    function toId(address operator_) internal pure returns (uint256) {
        return uint256(uint160(operator_));
    }

    function depositNFT() internal {
        vm.startPrank(operator);
        stakingMiddleware.mint();
        IERC721(address(stakingMiddleware)).safeTransferFrom(operator, address(stakeTableSync), toId(operator));
        vm.stopPrank();
    }

    function deposit(address user, uint96 amount) internal {
        stakeToken.mint(user, amount);
        vm.startPrank(user);
        stakeToken.approve(address(stakingMiddleware), amount);
        stakingMiddleware.stake(amount);
        vm.stopPrank();
    }

    function depositAndDelegate(address user, uint96 amount) internal {
        deposit(user, amount);
        vm.prank(operator);
        stakingMiddleware.setDelegationStatus(true);
        vm.prank(user);
        stakingMiddleware.delegate(operator);
    }

    /// forge-config: default.isolate = true
    function test_gas_reportOperatorStake() public onlyForked {
        vm.prank(address(stakingMiddleware));
        stakeTableSync.reportOperatorStake(address(this), DEFAULT_AMOUNT, address(this), DEFAULT_AMOUNT);
        vm.snapshotGasLastCall('reportOperatorStake');
    }

    /// forge-config: default.isolate = true
    function test_gas_depositERC721() public onlyForked {
        vm.startPrank(operator);
        stakingMiddleware.mint();
        IERC721(address(stakingMiddleware)).safeTransferFrom(operator, address(stakeTableSync), toId(operator));
        vm.snapshotGasLastCall('depositERC721');
        vm.stopPrank();
    }

    /// forge-config: default.isolate = true
    function test_gas_syncOperator() public onlyForked {
        vm.startPrank(operator);
        stakingMiddleware.mint();
        IERC721(address(stakingMiddleware)).safeTransferFrom(operator, address(stakeTableSync), toId(operator));
        vm.stopPrank();
        stakeTableSync.syncOperator(operator);
        vm.snapshotGasLastCall('syncOperator');
    }

    /// forge-config: default.isolate = true
    function test_slashing() public onlyForked {
        vm.prank(address(stakingMiddleware));
        stakeTableSync.reportOperatorSlash(operator, DEFAULT_AMOUNT);
        vm.snapshotGasLastCall('reportOperatorSlash');
    }

    /// forge-config: default.isolate = true
    function test_gas_onWithdrawal() public onlyForked {
        vm.prank(address(stakingMiddleware));
        stakeTableSync.onWithdrawal(operator);
        vm.snapshotGasLastCall('onWithdrawal');
    }

    function test_RevertIf_NotStakingMiddleware() public {
        vm.expectRevert(IStakeTableSync.NotStakingMiddleware.selector);
        stakeTableSync.reportOperatorStake(operator, DEFAULT_AMOUNT, address(this), DEFAULT_AMOUNT);
        vm.expectRevert(IStakeTableSync.NotStakingMiddleware.selector);
        stakeTableSync.reportOperatorSlash(operator, DEFAULT_AMOUNT);
        vm.expectRevert(IStakeTableSync.NotStakingMiddleware.selector);
        stakeTableSync.onWithdrawal(operator);
    }

    function test_ReportOperatorStake() public onlyForked {
        vm.expectEmit();
        emit IOptimismPortal2.TransactionDeposited(
            toAlias(address(stakeTableSync)),
            l2StakeTable,
            VERSION,
            abi.encodePacked(
                MINT_VALUE,
                VALUE,
                DEFAULT_GAS_LIMIT,
                IS_CREATION,
                abi.encodeWithSelector(
                    IBaseService.reportOperatorStake.selector,
                    address(this),
                    DEFAULT_AMOUNT,
                    address(this),
                    DEFAULT_AMOUNT
                )
            )
        );
        vm.prank(address(stakingMiddleware));
        stakeTableSync.reportOperatorStake(address(this), DEFAULT_AMOUNT, address(this), DEFAULT_AMOUNT);
    }

    function test_ReportOperatorSlash() public onlyForked {
        vm.expectEmit();
        emit IOptimismPortal2.TransactionDeposited(
            toAlias(address(stakeTableSync)),
            l2StakeTable,
            VERSION,
            abi.encodePacked(
                MINT_VALUE,
                VALUE,
                DEFAULT_GAS_LIMIT,
                IS_CREATION,
                abi.encodeWithSelector(IBaseService.reportOperatorSlash.selector, address(this), DEFAULT_AMOUNT)
            )
        );
        vm.prank(address(stakingMiddleware));
        stakeTableSync.reportOperatorSlash(address(this), DEFAULT_AMOUNT);
    }

    function test_ShouldSyncOperatorStakeOnDeposit() public onlyForked {
        vm.startPrank(operator);
        stakingMiddleware.mint();
        vm.expectEmit();
        emit IOptimismPortal2.TransactionDeposited(
            toAlias(address(stakeTableSync)),
            l2StakeTable,
            VERSION,
            abi.encodePacked(
                MINT_VALUE,
                VALUE,
                DEPLOY_GAS_LIMIT,
                IS_CREATION,
                abi.encodeWithSelector(IBaseService.reportOperatorStake.selector, operator, 0, address(0), 0)
            )
        );
        IERC721(address(stakingMiddleware)).safeTransferFrom(operator, address(stakeTableSync), toId(operator));
    }

    function test_ShouldSyncOperatorStakeOnDepositWithDelegation() public onlyForked {
        vm.startPrank(operator);
        stakingMiddleware.mint();
        IERC721(address(stakingMiddleware)).safeTransferFrom(operator, address(stakeTableSync), toId(operator));
        vm.stopPrank();
        depositAndDelegate(delegator, uint96(DEFAULT_AMOUNT));
        vm.startPrank(operator);
        IERC721(address(stakingMiddleware)).safeTransferFrom(address(stakeTableSync), operator, toId(operator));
        vm.expectEmit();
        emit IOptimismPortal2.TransactionDeposited(
            toAlias(address(stakeTableSync)),
            l2StakeTable,
            VERSION,
            abi.encodePacked(
                MINT_VALUE,
                VALUE,
                DEPLOY_GAS_LIMIT,
                IS_CREATION,
                abi.encodeWithSelector(
                    IBaseService.reportOperatorStake.selector, operator, DEFAULT_AMOUNT, address(0), 0
                )
            )
        );
        IERC721(address(stakingMiddleware)).safeTransferFrom(operator, address(stakeTableSync), toId(operator));
    }

    function test_RevertIf_DelegatorNotDelegated() public onlyForked {
        vm.startPrank(operator);
        stakingMiddleware.mint();
        IERC721(address(stakingMiddleware)).safeTransferFrom(operator, address(stakeTableSync), toId(operator));
        vm.stopPrank();
        depositAndDelegate(delegator, uint96(DEFAULT_AMOUNT));
        vm.prank(operator);
        IERC721(address(stakingMiddleware)).safeTransferFrom(address(stakeTableSync), operator, toId(operator));
        vm.expectRevert(IStakeTableSync.OperatorNotDeposited.selector);
        stakeTableSync.sync(delegator);
    }

    function test_RevertIf_OperatorNotDeposited() public onlyForked {
        vm.prank(operator);
        stakingMiddleware.mint();
        vm.expectRevert(IStakeTableSync.OperatorNotDeposited.selector);
        stakeTableSync.syncOperator(operator);
    }

    function test_ShouldBeAbleToSyncDelegatorStake() public onlyForked {
        depositNFT();
        depositAndDelegate(delegator, uint96(DEFAULT_AMOUNT));
        depositAndDelegate(makeAddr('delegator2'), uint96(DEFAULT_AMOUNT));
        vm.expectEmit();
        emit IOptimismPortal2.TransactionDeposited(
            toAlias(address(stakeTableSync)),
            l2StakeTable,
            VERSION,
            abi.encodePacked(
                MINT_VALUE,
                VALUE,
                DEFAULT_GAS_LIMIT,
                IS_CREATION,
                abi.encodeWithSelector(
                    IBaseService.reportOperatorStake.selector, operator, DEFAULT_AMOUNT * 2, delegator, DEFAULT_AMOUNT
                )
            )
        );
        stakeTableSync.sync(delegator);
    }

    function test_ShouldBeAbleToSyncOperatorStake() public onlyForked {
        depositNFT();
        depositAndDelegate(delegator, uint96(DEFAULT_AMOUNT));
        vm.expectEmit();
        emit IOptimismPortal2.TransactionDeposited(
            toAlias(address(stakeTableSync)),
            l2StakeTable,
            VERSION,
            abi.encodePacked(
                MINT_VALUE,
                VALUE,
                DEFAULT_GAS_LIMIT,
                IS_CREATION,
                abi.encodeWithSelector(
                    IBaseService.reportOperatorStake.selector, operator, DEFAULT_AMOUNT, address(0), 0
                )
            )
        );
        stakeTableSync.syncOperator(operator);
    }

    function test_ShouldSupportInterfaces() public view {
        assertTrue(stakeTableSync.supportsInterface(type(IService).interfaceId));
        assertTrue(stakeTableSync.supportsInterface(type(IERC165).interfaceId));
    }
}
