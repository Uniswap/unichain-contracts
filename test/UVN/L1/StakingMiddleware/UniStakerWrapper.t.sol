// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {IUniStaker, UniStakerDeployer} from '../../../deployers/UniStakerDeployer.sol';

import {L1TestHandler} from '../L1TestHandler.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract UniStakerWrapperHarness is UniStakerWrapper {
    constructor(IUniStaker unistaker_) UniStakerWrapper(unistaker_, msg.sender, 0, address(1)) {}

    function stakedBalanceOf(address delegator) external view returns (uint256) {
        return _stakedBalanceOf(delegator);
    }

    function totalAmountStaked() external view returns (uint256) {
        return _totalAmountDepositedIntoUniStaker();
    }

    function depositIntoUniStakerHarness(uint96 amount, address governanceDelegatee)
        external
        returns (uint256 depositId)
    {
        depositId = _depositIntoUniStaker(amount, governanceDelegatee);
    }

    function withdrawFromUniStakerHarness(uint96 amount) external {
        _withdrawFromUniStaker(amount);
    }
}

contract UniStakerWrapperTest is L1TestHandler {
    UniStakerWrapperHarness unistakerWrapper;

    function setUp() public override {
        super.setUp();
        stakeToken.mint(address(this), 1000);
        unistakerWrapper = new UniStakerWrapperHarness(unistaker);
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
        assertEq(unistakerWrapper.stakedBalanceOf(account), expected);
    }

    function expectERC20Transfer(address from, address to, uint256 amount) internal {
        vm.expectEmit();
        emit IERC20.Transfer(from, to, amount);
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
        assertEq(unistakerWrapper.totalAmountStaked(), 1000);
    }

    function test_delegateChangeAfterDeposit() public {
        unistakerWrapper.stake(1000);
        uint256 depositId = unistakerWrapper.depositIntoUniStaker(delegatee);
        address newDelegatee = makeAddr('newDelegatee');
        vm.expectEmit();
        emit IUniStaker.DelegateeAltered(toId(depositId), delegatee, newDelegatee);
        uint256 newDepositId = unistakerWrapper.depositIntoUniStakerHarness(0, newDelegatee);
        assertEq(newDepositId, depositId);
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
        assertEq(unistakerWrapper.totalAmountStaked(), initialBalance + subsequentDeposit);
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
        assertEq(unistakerWrapper.totalAmountStaked(), 900);
    }
}
