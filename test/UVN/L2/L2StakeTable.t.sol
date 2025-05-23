// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DefaultDelegatorClaim} from '../../../src/UVN/L2/DefaultDelegatorClaim.sol';
import {L2StakeTable} from '../../../src/UVN/L2/L2StakeTable.sol';

import {ExampleOperatorFeeManager} from '../../../src/UVN/L2/examples/ExampleOperatorFeeManager.sol';

import {IERC7751} from '../../../src/interfaces/IERC7751.sol';
import {IDelegatorClaim} from '../../../src/interfaces/UVN/L2/IDelegatorClaim.sol';
import {IL2StakeTable} from '../../../src/interfaces/UVN/L2/IL2StakeTable.sol';
import {Test} from 'forge-std/Test.sol';

contract L2StakeTableTest is Test {
    L2StakeTable stakeTable;

    address l1StakeTableSync;
    address operator1;
    address operator2;
    address delegator1;
    address delegator2;

    uint256 constant PERCENTAGE_DENOMINATOR = 1e18;
    uint256 constant OPERATOR_FEE_PERCENTAGE = 1e17; // 10%

    function setUp() public virtual {
        l1StakeTableSync = address(this);
        operator1 = makeAddr('operator1');
        operator2 = makeAddr('operator2');
        delegator1 = makeAddr('delegator1');
        delegator2 = makeAddr('delegator2');

        stakeTable = new L2StakeTable(l1StakeTableSync);
    }

    function test_constructor() public view {
        assertEq(stakeTable.L1_STAKE_TABLE_SYNC(), l1StakeTableSync);
    }

    /// forge-config: default.isolate = true
    function test_gas_reportOperatorStake_newOperator() public {
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        vm.snapshotGasLastCall('reportOperatorStake:deployDelegatorClaim');
    }

    /// forge-config: default.isolate = true
    function test_gas_reportOperatorStake_existingOperator_cold() public {
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
        vm.snapshotGasLastCall('reportOperatorStake:delegatorClaim:cold');
    }

    /// forge-config: default.isolate = true
    function test_gas_reportOperatorStake_existingOperator_warm() public {
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
        vm.snapshotGasLastCall('reportOperatorStake:delegatorClaim:warm');
    }

    /// forge-config: default.isolate = true
    function test_gas_reportOperatorStake_existingOperator_with() public {
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
        address delegatorClaim = stakeTable.beneficiary(operator1);
        (bool success,) = delegatorClaim.call{value: 1 ether}('');
        assertTrue(success);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
        vm.snapshotGasLastCall('reportOperatorStake:delegatorClaimWithRewards');
    }

    /// forge-config: default.isolate = true
    function test_gas_reportSlashing() public {
        stakeTable.reportOperatorStake(operator1, 0, address(0), 0);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
        vm.prank(l1StakeTableSync);
        stakeTable.reportOperatorSlash(operator1, 0.5 ether);
        vm.snapshotGasLastCall('reportOperatorSlash');
    }

    /// forge-config: default.isolate = true
    function test_gas_onWithdrawal() public {
        stakeTable.reportOperatorStake(operator1, 0, address(0), 0);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
        vm.prank(l1StakeTableSync);
        stakeTable.onWithdrawal(operator1);
        vm.snapshotGasLastCall('onWithdrawal');
    }

    function test_reportOperatorStake_newOperator() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        assertEq(stakeTable.getVotes(operator1), 100 ether);

        // Check default delegator claim contract was deployed
        address payable beneficiary = payable(stakeTable.beneficiary(operator1));
        assertTrue(beneficiary != address(0));

        DefaultDelegatorClaim delegatorClaim = DefaultDelegatorClaim(beneficiary);
        assertEq(delegatorClaim.OPERATOR(), operator1);
    }

    function test_reportOperatorStake_increaseStake() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        assertEq(stakeTable.getVotes(operator1), 100 ether);

        stakeTable.reportOperatorStake(operator1, 150 ether, address(0), 0);
        assertEq(stakeTable.getVotes(operator1), 150 ether);
    }

    function test_reportOperatorStake_decreaseStake() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        assertEq(stakeTable.getVotes(operator1), 100 ether);

        stakeTable.reportOperatorStake(operator1, 50 ether, address(0), 0);
        assertEq(stakeTable.getVotes(operator1), 50 ether);
    }

    function test_reportOperatorStake_updateDelegatorStake() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        // Get delegator claim address
        address payable delegatorClaimAddr = payable(stakeTable.beneficiary(operator1));
        DefaultDelegatorClaim delegatorClaim = DefaultDelegatorClaim(delegatorClaimAddr);

        // Report delegator stake
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 50 ether);

        assertEq(delegatorClaim.delegationOf(delegator1), 50 ether);
        assertEq(delegatorClaim.totalDelegation(), 50 ether);
    }

    function test_reportOperatorStake_multipleOperators() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        stakeTable.reportOperatorStake(operator2, 200 ether, address(0), 0);

        assertEq(stakeTable.getVotes(operator1), 100 ether);
        assertEq(stakeTable.getVotes(operator2), 200 ether);

        // Each should have a unique claim contract
        address claim1 = stakeTable.beneficiary(operator1);
        address claim2 = stakeTable.beneficiary(operator2);
        assertTrue(claim1 != claim2);
    }

    function test_reportOperatorStake_onlyL1StakeTableSync() public {
        vm.prank(operator1);
        vm.expectRevert(IL2StakeTable.NotStakeTableSync.selector);
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
    }

    function test_reportOperatorSlash() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        uint256 remainingPercentage = PERCENTAGE_DENOMINATOR / 2;
        stakeTable.reportOperatorSlash(operator1, remainingPercentage);

        assertEq(stakeTable.getVotes(operator1), 50 ether);
    }

    function test_reportOperatorSlash_fullSlash() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        stakeTable.reportOperatorSlash(operator1, 0);
        assertEq(stakeTable.getVotes(operator1), 0);
    }

    function test_reportOperatorSlash_onlyL1StakeTableSync() public {
        vm.prank(operator1);
        vm.expectRevert(IL2StakeTable.NotStakeTableSync.selector);
        stakeTable.reportOperatorSlash(operator1, PERCENTAGE_DENOMINATOR / 2);
    }

    function test_onWithdrawal() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        stakeTable.onWithdrawal(operator1);
        assertEq(stakeTable.getVotes(operator1), 0);
    }

    function test_onWithdrawal_onlyL1StakeTableSync() public {
        vm.prank(operator1);
        vm.expectRevert(IL2StakeTable.NotStakeTableSync.selector);
        stakeTable.onWithdrawal(operator1);
    }

    function test_RevertIf_overrideWithZeroAddress() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        vm.prank(operator1);
        vm.expectRevert(IL2StakeTable.ZeroAddress.selector);
        stakeTable.overrideDelegatorClaimContract(IDelegatorClaim(address(0)));
    }

    function test_overrideDelegatorClaimContract() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        address defaultClaim = stakeTable.beneficiary(operator1);

        MockDelegatorClaim customClaim = new MockDelegatorClaim();

        vm.prank(operator1);
        stakeTable.overrideDelegatorClaimContract(customClaim);

        assertEq(stakeTable.beneficiary(operator1), address(customClaim));
        assertNotEq(stakeTable.beneficiary(operator1), defaultClaim);
    }

    function test_overrideDelegatorClaimContract_onlyOperator() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        MockDelegatorClaim customClaim = new MockDelegatorClaim();
        vm.prank(operator2);
        stakeTable.overrideDelegatorClaimContract(customClaim);

        assertEq(stakeTable.beneficiary(operator2), address(customClaim));
        assertNotEq(stakeTable.beneficiary(operator1), address(customClaim));
    }

    function test_shouldNotRevertIfOverrideIsEOA() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);
        vm.prank(operator1);
        address eoa = makeAddr('EOA');
        stakeTable.overrideDelegatorClaimContract(IDelegatorClaim(eoa));
        assertEq(stakeTable.beneficiary(operator1), eoa);
        vm.expectEmit(true, true, false, true);
        emit IL2StakeTable.DelegatorStakeUpdateFailed(
            operator1,
            delegator1,
            abi.encodeWithSelector(
                IERC7751.WrappedError.selector,
                eoa,
                IDelegatorClaim.reportDelegatorStake.selector,
                IL2StakeTable.NoCode.selector,
                ''
            )
        );
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);
    }

    function test_delegateDisabled() public {
        vm.prank(delegator1);
        vm.expectRevert(IL2StakeTable.DelegationDisabled.selector);
        stakeTable.delegate(operator1);
    }

    function test_delegateBySigDisabled() public {
        vm.expectRevert(IL2StakeTable.DelegationDisabled.selector);
        stakeTable.delegateBySig(operator1, 0, 0, 0, bytes32(0), bytes32(0));
    }

    function test_delegates() public view {
        assertEq(stakeTable.delegates(operator1), operator1);
    }

    function testFuzz_reportOperatorStake(uint256 initialStake, uint256 newStake) public {
        initialStake = bound(initialStake, 1, 1e36);
        newStake = bound(newStake, 1, 1e36);

        stakeTable.reportOperatorStake(operator1, initialStake, address(0), 0);
        assertEq(stakeTable.getVotes(operator1), initialStake);

        stakeTable.reportOperatorStake(operator1, newStake, address(0), 0);
        assertEq(stakeTable.getVotes(operator1), newStake);
    }

    function testFuzz_reportOperatorSlash(uint256 initialStake, uint256 slashPercentage) public {
        initialStake = bound(initialStake, 1, 1e36);
        slashPercentage = bound(slashPercentage, 0, PERCENTAGE_DENOMINATOR);

        stakeTable.reportOperatorStake(operator1, initialStake, address(0), 0);
        stakeTable.reportOperatorSlash(operator1, slashPercentage);

        uint256 expectedStake = (initialStake * slashPercentage) / PERCENTAGE_DENOMINATOR;
        assertEq(stakeTable.getVotes(operator1), expectedStake);
    }

    function test_delegatorStakeUpdateFailure() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        // Assign a failing claim contract
        FailingDelegatorClaim failingClaim = new FailingDelegatorClaim();
        vm.prank(operator1);
        stakeTable.overrideDelegatorClaimContract(failingClaim);

        // Try to update delegator stake (should not revert)
        vm.expectEmit(true, true, true, true);
        emit IL2StakeTable.DelegatorStakeUpdateFailed(
            operator1,
            delegator1,
            abi.encodeWithSelector(
                IERC7751.WrappedError.selector,
                address(failingClaim),
                IDelegatorClaim.reportDelegatorStake.selector,
                abi.encodeWithSignature('Error(string)', 'oh no something went wrong :('),
                ''
            )
        );
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 50 ether);

        // Operator stake should still be updated
        assertEq(stakeTable.getVotes(operator1), 100 ether);
    }

    function test_integration_rewardDistribution() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        // Get delegator claim contract
        address payable delegatorClaimAddr = payable(stakeTable.beneficiary(operator1));
        DefaultDelegatorClaim delegatorClaim = DefaultDelegatorClaim(delegatorClaimAddr);

        // Add delegators
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 50 ether);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator2, 50 ether);

        // Send rewards to the delegator claim contract
        vm.deal(address(this), 10 ether);
        (bool success,) = delegatorClaimAddr.call{value: 10 ether}('');
        assertTrue(success);

        // Verify rewards distribution (50% each)
        assertEq(delegatorClaim.rewardsOf(delegator1), 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 5 ether);
    }

    function test_integration_rewardDistributionAfterStakeChange() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        address payable delegatorClaimAddr = payable(stakeTable.beneficiary(operator1));
        DefaultDelegatorClaim delegatorClaim = DefaultDelegatorClaim(delegatorClaimAddr);

        // Add delegators with equal initial stake
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 50 ether);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator2, 50 ether);

        // Send initial rewards (5 ether each)
        vm.deal(address(this), 10 ether);
        (bool success,) = delegatorClaimAddr.call{value: 10 ether}('');
        assertTrue(success);

        // Update delegator stakes (75/25 split)
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 75 ether);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator2, 25 ether);

        // Send more rewards
        vm.deal(address(this), 10 ether);
        (success,) = delegatorClaimAddr.call{value: 10 ether}('');
        assertTrue(success);

        // Check total rewards:
        // delegator1: 5 (initial) + 7.5 (75% of second distribution) = 12.5 ether
        // delegator2: 5 (initial) + 2.5 (25% of second distribution) = 7.5 ether
        assertEq(delegatorClaim.rewardsOf(delegator1), 12.5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 7.5 ether);
    }

    function test_integration_rewardDistributionWithFees() public {
        // Setup operator and delegators
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        address payable delegatorClaimAddr = payable(stakeTable.beneficiary(operator1));
        DefaultDelegatorClaim delegatorClaim = DefaultDelegatorClaim(delegatorClaimAddr);

        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 50 ether);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator2, 50 ether);

        // Assign fee manager with 10% fee
        ExampleOperatorFeeManager feeManager = new ExampleOperatorFeeManager(operator1, OPERATOR_FEE_PERCENTAGE);
        vm.prank(operator1);
        delegatorClaim.setOperatorFeeManager(feeManager);

        vm.deal(address(this), 10 ether);
        (bool success,) = delegatorClaimAddr.call{value: 10 ether}('');
        assertTrue(success);

        // Check rewards:
        // 10% operator fee = 1 ether
        // Remaining 9 ether split 50/50 = 4.5 ether each
        assertEq(delegatorClaim.rewardsOf(delegator1), 4.5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator2), 4.5 ether);
        assertEq(operator1.balance, 1 ether);
    }

    function test_integration_claimRewards() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        address payable delegatorClaimAddr = payable(stakeTable.beneficiary(operator1));
        DefaultDelegatorClaim delegatorClaim = DefaultDelegatorClaim(delegatorClaimAddr);

        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 50 ether);
        stakeTable.reportOperatorStake(operator1, 100 ether, delegator2, 50 ether);

        vm.deal(address(this), 10 ether);
        (bool success,) = delegatorClaimAddr.call{value: 10 ether}('');
        assertTrue(success);

        vm.prank(delegator1);
        delegatorClaim.claimRewards(delegator1, delegator1);

        assertEq(delegator1.balance, 5 ether);
        assertEq(delegatorClaim.rewardsOf(delegator1), 0);
        assertEq(delegatorClaim.rewardsOf(delegator2), 5 ether);
    }

    function test_integration_delegatorStakeAfterSlashing() public {
        stakeTable.reportOperatorStake(operator1, 100 ether, address(0), 0);

        address payable delegatorClaimAddr = payable(stakeTable.beneficiary(operator1));
        DefaultDelegatorClaim delegatorClaim = DefaultDelegatorClaim(delegatorClaimAddr);

        stakeTable.reportOperatorStake(operator1, 100 ether, delegator1, 100 ether);

        vm.deal(address(this), 10 ether);
        (bool success,) = delegatorClaimAddr.call{value: 10 ether}('');
        assertTrue(success);

        // Slash operator by 50%
        stakeTable.reportOperatorSlash(operator1, PERCENTAGE_DENOMINATOR / 2);

        // Check operator stake is 50 ether now
        assertEq(stakeTable.getVotes(operator1), 50 ether);

        // Note: delegator stake in the delegator claim contract is not automatically
        // updated when slashing the operator. This would happen via a separate call
        // to reportOperatorStake with the updated delegator stake.
        stakeTable.reportOperatorStake(operator1, 50 ether, delegator1, 50 ether);

        // Verify delegator stake was updated
        assertEq(delegatorClaim.delegationOf(delegator1), 50 ether);

        // Send more rewards
        vm.deal(address(this), 10 ether);
        (success,) = delegatorClaimAddr.call{value: 10 ether}('');
        assertTrue(success);

        // Verify rewards (10 from before slash + 10 after)
        assertEq(delegatorClaim.rewardsOf(delegator1), 20 ether);
    }

    receive() external payable {}
}

contract MockDelegatorClaim is IDelegatorClaim {
    mapping(address => uint256) public stakes;

    function reportDelegatorStake(address delegator, uint256 newStake) external override {
        stakes[delegator] = newStake;
    }
}

contract FailingDelegatorClaim is IDelegatorClaim {
    function reportDelegatorStake(address, uint256) external pure override {
        revert('oh no something went wrong :(');
    }
}
