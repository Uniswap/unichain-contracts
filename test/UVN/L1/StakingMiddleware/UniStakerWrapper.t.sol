// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IUniStakerWrapper, UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {IUniStaker, UniStakerDeployer} from '../../../deployers/UniStakerDeployer.sol';

import {L1TestHandler} from '../L1TestHandler.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract UniStakerWrapperHarness is UniStakerWrapper {
    constructor(IUniStaker unistaker, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        UniStakerWrapper(unistaker, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {}

    function slashDelegatorStake(address delegator, uint96 newStake, uint96 newPendingWithdrawalAmount) external {
        _slashDelegatorStake(delegator, newStake, newPendingWithdrawalAmount);
    }
}

contract UniStakerWrapperTest is L1TestHandler {
    UniStakerWrapperHarness unistakerWrapper;

    function setUp() public override {
        super.setUp();
        stakeToken.mint(address(this), 1000);
        unistakerWrapper = new UniStakerWrapperHarness(unistaker, address(this), 0, slashingBeneficiary);
        stakeToken.approve(address(unistakerWrapper), 1000);
        // use up the first depositId 0
        unistaker.stake(0, delegatee);
    }

    function toId(uint256 i) internal pure returns (IUniStaker.DepositIdentifier) {
        return IUniStaker.DepositIdentifier.wrap(i);
    }

    function assertEq(IUniStaker.DepositIdentifier a, IUniStaker.DepositIdentifier b) internal pure {
        assertEq(IUniStaker.DepositIdentifier.unwrap(a), IUniStaker.DepositIdentifier.unwrap(b));
    }

    function assertBalance(address account, uint256 expected) internal view {
        uint256 balance =
            unistakerWrapper.isDepositedIntoUniStaker(account) ? unistakerWrapper.delegatorStake(account) : 0;
        assertEq(balance, expected);
    }

    function assertTotalAmountStaked(uint256 expected) internal view {
        assertEq(unistaker.depositorTotalStaked(address(unistakerWrapper)), expected);
    }

    function expectERC20Transfer(address from, address to, uint256 amount) internal {
        vm.expectEmit();
        emit IERC20.Transfer(from, to, amount);
    }

    function deposit(address account, uint96 amount) internal returns (uint256 depositId) {
        stakeToken.mint(account, amount);
        vm.startPrank(account);
        stakeToken.approve(address(unistakerWrapper), type(uint96).max);
        unistakerWrapper.stake(amount);
        depositId = unistakerWrapper.depositIntoUniStaker(delegatee);
        vm.stopPrank();
    }

    function test_RevertIf_withdrawingWhileNotDeposited() public {
        vm.expectRevert(abi.encodeWithSelector(IUniStakerWrapper.NotDepositedIntoUniStaker.selector));
        unistakerWrapper.withdrawFromUniStaker();
    }

    function test_RevertIf_alteringGovernanceDelegateeWhileNotDeposited() public {
        vm.expectRevert(abi.encodeWithSelector(IUniStakerWrapper.NotDepositedIntoUniStaker.selector));
        unistakerWrapper.alterGovernanceDelegatee(delegatee);
    }

    function test_RevertIf_depositingWhileAlreadyDeposited() public {
        deposit(address(this), 1000);
        vm.expectRevert(abi.encodeWithSelector(IUniStakerWrapper.AlreadyDepositedIntoUniStaker.selector));
        unistakerWrapper.depositIntoUniStaker(delegatee);
    }

    function test_RevertIf_depositingWhileNotStakingAnyAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IUniStakerWrapper.NoStakeToDeposit.selector));
        unistakerWrapper.depositIntoUniStaker(delegatee);
    }

    function test_depositIntoUniStakerInitially() public {
        IUniStaker.DepositIdentifier nextDepositId = IUniStaker.DepositIdentifier.wrap(1);
        expectERC20Transfer(address(this), address(unistakerWrapper), 1000);
        unistakerWrapper.stake(1000);
        vm.expectEmit();
        emit IUniStaker.StakeDeposited(address(unistakerWrapper), nextDepositId, 1000, 1000);
        vm.expectEmit();
        emit IUniStaker.BeneficiaryAltered(nextDepositId, address(0), address(unistakerWrapper));
        vm.expectEmit();
        emit IUniStaker.DelegateeAltered(nextDepositId, address(0), delegatee);
        unistakerWrapper.depositIntoUniStaker(delegatee);
        assertBalance(address(this), 1000);
        assertTotalAmountStaked(1000);
        assertTrue(unistakerWrapper.isDepositedIntoUniStaker(address(this)));
    }

    function test_delegateChangeAfterDeposit() public {
        unistakerWrapper.stake(1000);
        uint256 depositId = unistakerWrapper.depositIntoUniStaker(delegatee);
        address newDelegatee = makeAddr('newDelegatee');
        vm.expectEmit();
        emit IUniStaker.DelegateeAltered(toId(depositId), delegatee, newDelegatee);
        unistakerWrapper.alterGovernanceDelegatee(newDelegatee);
    }

    function test_stakeMore() public {
        uint96 initialBalance = 100;
        unistakerWrapper.stake(initialBalance);
        uint256 depositId = unistakerWrapper.depositIntoUniStaker(delegatee);
        uint96 subsequentDeposit = 200;
        expectERC20Transfer(address(this), address(unistakerWrapper), subsequentDeposit);
        vm.expectEmit();
        emit IUniStaker.StakeDeposited(
            address(unistakerWrapper), toId(depositId), subsequentDeposit, initialBalance + subsequentDeposit
        );
        unistakerWrapper.stake(subsequentDeposit);
        assertBalance(address(this), initialBalance + subsequentDeposit);
        assertTotalAmountStaked(initialBalance + subsequentDeposit);
    }

    function test_withdrawal() public {
        unistakerWrapper.stake(1000);
        uint256 depositId = unistakerWrapper.depositIntoUniStaker(delegatee);
        uint96 withdrawalAmount = 100;
        unistakerWrapper.unstake(withdrawalAmount);
        vm.expectEmit();
        emit IUniStaker.StakeWithdrawn(toId(depositId), withdrawalAmount, 900);
        expectERC20Transfer(address(unistakerWrapper), address(this), withdrawalAmount);
        unistakerWrapper.withdraw(address(this), 1);
        assertBalance(address(this), 900);
        assertTotalAmountStaked(900);
        assertTrue(unistakerWrapper.isDepositedIntoUniStaker(address(this)));
    }

    function test_withdrawalCompleteBalance() public {
        uint96 stakeAmount = 1000;
        unistakerWrapper.stake(stakeAmount);
        uint256 depositId = unistakerWrapper.depositIntoUniStaker(delegatee);
        unistakerWrapper.unstake(stakeAmount);
        vm.expectEmit();
        emit IUniStaker.StakeWithdrawn(toId(depositId), stakeAmount, 0);
        expectERC20Transfer(address(unistakerWrapper), address(this), stakeAmount);
        unistakerWrapper.withdraw(address(this), 1);
        assertBalance(address(this), 0);
        assertTotalAmountStaked(0);
        assertFalse(unistakerWrapper.isDepositedIntoUniStaker(address(this)));
    }

    function test_stakeAfterCompleteWithdrawalShouldIssueNewDepositId() public {
        uint96 stakeAmount = 1000;
        unistakerWrapper.stake(stakeAmount);
        uint256 depositId = unistakerWrapper.depositIntoUniStaker(delegatee);
        unistakerWrapper.unstake(stakeAmount);
        vm.expectEmit();
        emit IUniStaker.StakeWithdrawn(toId(depositId), stakeAmount, 0);
        expectERC20Transfer(address(unistakerWrapper), address(this), stakeAmount);
        unistakerWrapper.withdraw(address(this), 1);
        assertBalance(address(this), 0);
        assertTotalAmountStaked(0);
        assertFalse(unistakerWrapper.isDepositedIntoUniStaker(address(this)));
        uint256 newDepositId = deposit(delegator, stakeAmount);
        assertEq(newDepositId, depositId + 1);
    }

    function test_shouldAutoDepositNewStakeWhenDeposited() public {
        deposit(address(this), 1000);
        uint96 newAmount = 500;
        uint256 unistakerBalanceBefore = unistaker.depositorTotalStaked(address(unistakerWrapper));
        unistakerWrapper.stake(newAmount);
        assertTotalAmountStaked(unistakerBalanceBefore + newAmount);
    }

    function test_shouldAutoWithdrawFromUnistakerWhenDeposited() public {
        deposit(address(this), 1000);
        uint96 withdrawalAmount = 500;
        uint256 unistakerBalanceBefore = unistaker.depositorTotalStaked(address(unistakerWrapper));
        unistakerWrapper.unstake(withdrawalAmount);
        unistakerWrapper.withdraw(address(this), 1);
        assertTotalAmountStaked(unistakerBalanceBefore - withdrawalAmount);
    }

    function test_shouldNotAutoDepositOrWithdrawFromUnistakerIfNotDeposited() public {
        // populate multiple depositIds
        uint96 stakeAmount = 1000;
        deposit(address(this), stakeAmount);
        deposit(delegator, stakeAmount);

        // withdraw again from one of the operators
        unistakerWrapper.withdrawFromUniStaker();

        // unistaker balance should not change when withdrawn delegator changes their stake
        uint256 unistakerBalanceBefore = unistaker.depositorTotalStaked(address(unistakerWrapper));
        assertTotalAmountStaked(unistakerBalanceBefore);
        unistakerWrapper.stake(stakeAmount);
        assertTotalAmountStaked(unistakerBalanceBefore);

        unistakerWrapper.unstake(stakeAmount);
        unistakerWrapper.withdraw(address(this), 1);
        assertTotalAmountStaked(unistakerBalanceBefore);
    }

    function test_shouldResetDepositIdOnFullWithdrawal() public {
        uint256 depositId = deposit(address(this), 1000);
        unistakerWrapper.unstake(1000);
        unistakerWrapper.withdraw(address(this), 1);

        uint256 newDepositId = deposit(address(this), 1000);
        assertNotEq(newDepositId, depositId);
    }

    function test_shouldWithdrawSlashedAmountBeforeSlashing() public {
        uint96 stakeAmount = 1000;
        uint256 remainingPercentage = 0.4e18;
        uint256 remainingStake = stakeAmount * remainingPercentage / 1e18;
        deposit(address(this), stakeAmount);
        unistakerWrapper.slashDelegatorStake(address(this), uint96(remainingStake), 0);
        assertBalance(address(this), remainingStake);
        assertTotalAmountStaked(remainingStake);
        assertEq(stakeToken.balanceOf(slashingBeneficiary), stakeAmount - remainingStake);
    }

    function test_shouldDepositPendingWithdrawals() public {
        unistakerWrapper.stake(10);
        unistakerWrapper.unstake(9);
        unistakerWrapper.depositIntoUniStaker(delegatee);
        assertTotalAmountStaked(10);
        unistakerWrapper.withdraw(address(this), 1);
    }
}
