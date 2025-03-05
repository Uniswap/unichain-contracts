// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {IUniStaker, UniStakerDeployer} from '../../../deployers/UniStakerDeployer.sol';
import {MockVotesToken} from '../../../mock/MockVotesToken.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Test} from 'forge-std/Test.sol';

contract UniStakerWrapperHarness is UniStakerWrapper {
    constructor(IUniStaker unistaker_) UniStakerWrapper(unistaker_) {}

    function depositIntoUniStaker(uint96 amount, address delegatee)
        external
        returns (IUniStaker.DepositIdentifier depositId)
    {
        depositId = IUniStaker.DepositIdentifier.wrap(_depositIntoUniStaker(amount, delegatee));
    }

    function withdrawFromUniStaker(uint96 amount) external {
        _withdrawFromUniStaker(amount);
    }

    function stakedBalanceOf(address delegator) external view returns (uint256) {
        return _stakedBalanceOf(delegator);
    }

    function totalAmountStaked() external view returns (uint256) {
        return _totalAmountStaked();
    }
}

contract UniStakerWrapperTest is Test {
    IUniStaker unistaker;
    MockVotesToken stakeToken;
    MockVotesToken rewardToken;
    UniStakerWrapperHarness unistakerWrapper;
    address delegatee = makeAddr('delegatee');

    function setUp() public {
        stakeToken = new MockVotesToken();
        rewardToken = new MockVotesToken();
        stakeToken.mint(address(this), 1000);
        unistaker = UniStakerDeployer.deploy(address(rewardToken), address(stakeToken), address(this));
        unistakerWrapper = new UniStakerWrapperHarness(unistaker);
        stakeToken.approve(address(unistakerWrapper), 1000);
        // use up the first depositId 0
        unistaker.stake(0, delegatee);
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
        vm.expectEmit();
        emit IUniStaker.StakeDeposited(address(unistakerWrapper), nextDepositId, 1000, 1000);
        vm.expectEmit();
        emit IUniStaker.BeneficiaryAltered(nextDepositId, address(0), address(unistakerWrapper));
        vm.expectEmit();
        emit IUniStaker.DelegateeAltered(nextDepositId, address(0), delegatee);
        unistakerWrapper.depositIntoUniStaker(1000, delegatee);
        assertBalance(address(this), 1000);
        assertEq(unistakerWrapper.totalAmountStaked(), 1000);
    }

    function test_delegateChangeAfterDeposit() public {
        IUniStaker.DepositIdentifier depositId = unistakerWrapper.depositIntoUniStaker(1000, delegatee);
        address newDelegatee = makeAddr('newDelegatee');
        vm.expectEmit();
        emit IUniStaker.DelegateeAltered(depositId, delegatee, newDelegatee);
        IUniStaker.DepositIdentifier newDepositId = unistakerWrapper.depositIntoUniStaker(0, newDelegatee);
        assertEq(newDepositId, depositId);
    }

    function test_stakeMore() public {
        uint256 initialBalance = 100;
        IUniStaker.DepositIdentifier depositId =
            unistakerWrapper.depositIntoUniStaker(uint96(initialBalance), delegatee);
        uint256 subsequentDeposit = 200;
        expectERC20Transfer(address(this), address(unistakerWrapper), subsequentDeposit);
        vm.expectEmit();
        emit IUniStaker.StakeDeposited(
            address(unistakerWrapper), depositId, subsequentDeposit, initialBalance + subsequentDeposit
        );
        unistakerWrapper.depositIntoUniStaker(uint96(subsequentDeposit), address(0));
        assertBalance(address(this), initialBalance + subsequentDeposit);
        assertEq(unistakerWrapper.totalAmountStaked(), initialBalance + subsequentDeposit);
    }

    function test_stakeMorewithDelegateeChange() public {
        uint256 initialBalance = 100;
        IUniStaker.DepositIdentifier depositId =
            unistakerWrapper.depositIntoUniStaker(uint96(initialBalance), delegatee);
        address newDelegatee = makeAddr('newDelegatee');
        uint256 subsequentDeposit = 200;
        expectERC20Transfer(address(this), address(unistakerWrapper), subsequentDeposit);
        vm.expectEmit();
        emit IUniStaker.StakeDeposited(
            address(unistakerWrapper), depositId, uint96(subsequentDeposit), uint96(initialBalance + subsequentDeposit)
        );
        vm.expectEmit();
        emit IUniStaker.DelegateeAltered(depositId, delegatee, newDelegatee);
        unistakerWrapper.depositIntoUniStaker(uint96(subsequentDeposit), newDelegatee);
        assertBalance(address(this), initialBalance + subsequentDeposit);
        assertEq(unistakerWrapper.totalAmountStaked(), initialBalance + subsequentDeposit);
    }

    function test_withdrawal() public {
        IUniStaker.DepositIdentifier depositId = unistakerWrapper.depositIntoUniStaker(1000, delegatee);
        uint256 withdrawalAmount = 100;
        vm.expectEmit();
        emit IUniStaker.StakeWithdrawn(depositId, withdrawalAmount, 900);
        expectERC20Transfer(address(unistakerWrapper), address(this), withdrawalAmount);
        unistakerWrapper.withdrawFromUniStaker(uint96(withdrawalAmount));
        assertBalance(address(this), 900);
        assertEq(unistakerWrapper.totalAmountStaked(), 900);
    }
}
