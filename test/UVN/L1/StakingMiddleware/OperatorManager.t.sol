// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IOperatorManager, OperatorManager} from '../../../../src/UVN/L1/StakingMiddleware/OperatorManager.sol';
import {UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {IUniStaker} from '../../../../src/interfaces/UVN/L1/IUnistaker.sol';
import {IDelegatorAccessControl} from '../../../../src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol';
import {IDelegatorVerifier} from '../../../../src/interfaces/UVN/L1/StakingMiddleware/IDelegatorVerifier.sol';

import {L1TestHandler} from '../L1TestHandler.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract OperatorManagerHarness is OperatorManager {
    IUniStaker private immutable _unistaker;

    constructor(
        string memory name,
        IUniStaker unistaker_,
        address initialAdmin,
        uint256 withdrawalDelay_,
        address slashingBeneficiary_
    ) OperatorManager(name) UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_) {
        _unistaker = unistaker_;
    }

    function getVotingUnits(address delegator) public view returns (uint256) {
        return _getVotingUnits(delegator);
    }

    function slashOperatorVotes(address operator, uint96 remainingPercentage) public {
        _slashOperatorVotes(operator, remainingPercentage);
    }
}

contract OperatorManagerTest is L1TestHandler {
    uint96 private constant DEFAULT_AMOUNT = 1000 ether;

    string private NAME = 'UVN Staking Middleware';

    OperatorManagerHarness operatorManager;

    uint256 delegatorPk;

    function setUp() public override {
        super.setUp();

        // Deploy the harness
        operatorManager = new OperatorManagerHarness(NAME, unistaker, address(this), 0, slashingBeneficiary);
        operatorManager.grantRole(operatorManager.PARAMS_SETTER_ROLE(), address(this));

        (delegator, delegatorPk) = makeAddrAndKey('delegator');

        stakeToken.mint(address(this), DEFAULT_AMOUNT);
        stakeToken.mint(delegator, DEFAULT_AMOUNT);
        stakeToken.mint(operator, DEFAULT_AMOUNT);

        stakeToken.approve(address(operatorManager), DEFAULT_AMOUNT);
        vm.prank(delegator);
        stakeToken.approve(address(operatorManager), DEFAULT_AMOUNT);
    }

    function stake(address delegator_, uint96 amount) internal {
        vm.startPrank(delegator_);
        stakeToken.mint(delegator_, amount);
        stakeToken.approve(address(operatorManager), amount);
        operatorManager.stake(amount);
        vm.stopPrank();
    }

    // Helper function to create a valid signature for delegateBySig
    function createSignature(uint256 privateKey, address operator_, uint256 nonce, uint256 expiry)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)'), operator_, nonce, expiry
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(abi.encodePacked(NAME)),
                keccak256('1'),
                block.chainid,
                address(operatorManager)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        return vm.sign(privateKey, digest);
    }

    function assertTotalVotes(uint256 expected) internal {
        assertTotalVotes(expected, '');
    }

    function assertTotalVotes(uint256 expected, string memory message) internal {
        uint256 blockNumber = vm.getBlockNumber();
        vm.roll(blockNumber + 1);
        assertEq(operatorManager.getPastTotalSupply(blockNumber), expected, message);
    }

    function test_votingUnitsShouldMatchStake(uint96 stakeAmount) public {
        assertEq(operatorManager.getVotingUnits(delegator), 0, 'initial voting units should be 0');
        stake(delegator, stakeAmount);
        assertEq(operatorManager.getVotingUnits(delegator), stakeAmount, 'voting units should match stake');
    }

    function test_shouldBeAbleToDelegate() public {
        assertEq(operatorManager.delegates(delegator), address(0), 'delegator should not be delegated initially');
        vm.prank(delegator);
        operatorManager.delegate(operator);
        assertEq(operatorManager.delegates(delegator), operator, 'delegator should be delegated to operator');
    }

    function test_shouldBeAbleToDelegateBySignature() public {
        assertEq(operatorManager.delegates(delegator), address(0), 'delegator should not be delegated initially');
        (uint8 v, bytes32 r, bytes32 s) = createSignature(delegatorPk, operator, 0, block.timestamp);
        vm.prank(delegator);
        operatorManager.delegateBySig(operator, 0, block.timestamp, v, r, s);
        assertEq(operatorManager.delegates(delegator), operator, 'delegator should be delegated to operator');
    }

    function test_shouldIncreaseVotesOnStakeAfterDelegation() public {
        operatorManager.delegate(operator);
        assertEq(operatorManager.getVotes(operator), 0, 'initial votes should be 0');
        operatorManager.stake(DEFAULT_AMOUNT);
        assertEq(operatorManager.getVotes(operator), DEFAULT_AMOUNT, 'votes should match stake');
        assertEq(operatorManager.slashableOperatorStake(operator), DEFAULT_AMOUNT, 'slashable stake should match stake');
        assertTotalVotes(DEFAULT_AMOUNT, 'total votes should match stake');
    }

    function test_shouldDecreaseVotesOnUnstakeAfterDelegation(uint96 unstakeAmount) public {
        unstakeAmount = uint96(bound(unstakeAmount, 0, DEFAULT_AMOUNT));
        operatorManager.delegate(operator);
        operatorManager.stake(DEFAULT_AMOUNT);
        assertEq(operatorManager.getVotes(operator), DEFAULT_AMOUNT, 'votes should match stake');
        operatorManager.unstake(unstakeAmount);
        assertEq(operatorManager.getVotes(operator), DEFAULT_AMOUNT - unstakeAmount, 'votes should decrease on unstake');
        assertTotalVotes(DEFAULT_AMOUNT - unstakeAmount, 'total votes should decrease on unstake');
    }

    function test_shouldNotDecreaseSlashableStakeOnUnstakeAfterDelegation(uint96 unstakeAmount) public {
        unstakeAmount = uint96(bound(unstakeAmount, 0, DEFAULT_AMOUNT));
        operatorManager.delegate(operator);
        operatorManager.stake(DEFAULT_AMOUNT);
        assertEq(operatorManager.slashableOperatorStake(operator), DEFAULT_AMOUNT, 'slashable stake should match stake');
        operatorManager.unstake(unstakeAmount);
        assertEq(
            operatorManager.slashableOperatorStake(operator),
            DEFAULT_AMOUNT,
            'slashable stake should not decrease on unstake'
        );
    }

    function test_shouldDecreaseSlashableStakeOnWithdrawAfterDelegation(uint96 withdrawAmount) public {
        withdrawAmount = uint96(bound(withdrawAmount, 0, DEFAULT_AMOUNT));
        operatorManager.delegate(operator);
        operatorManager.stake(DEFAULT_AMOUNT);
        assertEq(operatorManager.slashableOperatorStake(operator), DEFAULT_AMOUNT, 'slashable stake should match stake');
        operatorManager.unstake(withdrawAmount);
        operatorManager.withdraw(address(this), 1);
        assertEq(
            operatorManager.slashableOperatorStake(operator),
            DEFAULT_AMOUNT - withdrawAmount,
            'slashable stake should decrease on withdraw'
        );
    }

    function test_shouldNotDecreaseVotesOnWithdrawAfterDelegation(uint96 withdrawAmount) public {
        withdrawAmount = uint96(bound(withdrawAmount, 0, DEFAULT_AMOUNT));
        operatorManager.delegate(operator);
        operatorManager.stake(DEFAULT_AMOUNT);
        assertEq(operatorManager.getVotes(operator), DEFAULT_AMOUNT, 'votes should match stake');
        assertTotalVotes(DEFAULT_AMOUNT, 'total votes should match stake');
        operatorManager.unstake(withdrawAmount);
        assertEq(
            operatorManager.getVotes(operator), DEFAULT_AMOUNT - withdrawAmount, 'votes should decrease on unstake'
        );
        assertTotalVotes(DEFAULT_AMOUNT - withdrawAmount, 'total votes should decrease on unstake');
        operatorManager.withdraw(address(this), 1);
        assertEq(
            operatorManager.getVotes(operator), DEFAULT_AMOUNT - withdrawAmount, 'votes should not decrease on withdraw'
        );
        assertTotalVotes(DEFAULT_AMOUNT - withdrawAmount, 'total votes should not decrease on withdraw');
    }

    function test_shouldNotBeAbleToDelegateWhileAlreadyDelegating() public {
        operatorManager.delegate(operator);
        vm.expectRevert(IOperatorManager.OperatorAlreadySelected.selector);
        operatorManager.delegate(operator);
    }

    function test_shouldNotBeAbleToDelegateWhileUndelegationIsPending() public {
        operatorManager.updateWithdrawalDelay(1);
        operatorManager.delegate(operator);
        operatorManager.announceOperatorUndelegation();
        vm.expectRevert(abi.encodeWithSelector(IOperatorManager.UndelegationNotFinalized.selector, block.timestamp + 1));
        operatorManager.delegate(operator);
    }

    function test_shouldIncreaseVotesOnDelegate() public {
        operatorManager.stake(DEFAULT_AMOUNT);
        assertEq(operatorManager.getVotes(operator), 0, 'initial votes should be 0');
        operatorManager.delegate(operator);
        assertEq(operatorManager.getVotes(operator), DEFAULT_AMOUNT, 'votes should match stake');
    }

    function test_shouldIncreaseSlashableStakeOnDelegate() public {
        operatorManager.stake(DEFAULT_AMOUNT);
        assertEq(operatorManager.slashableOperatorStake(operator), 0, 'initial slashable stake should be 0');
        operatorManager.delegate(operator);
        assertEq(operatorManager.slashableOperatorStake(operator), DEFAULT_AMOUNT, 'slashable stake should match stake');
    }

    function test_shouldDecreaseVotesOnUndelegationAnnouncement() public {
        operatorManager.stake(DEFAULT_AMOUNT);
        operatorManager.delegate(operator);
        vm.startPrank(delegator);
        operatorManager.stake(DEFAULT_AMOUNT);
        operatorManager.delegate(operator);
        assertEq(
            operatorManager.getVotes(operator), DEFAULT_AMOUNT * 2, 'initial votes should match total delegated stake'
        );
        assertTotalVotes(DEFAULT_AMOUNT * 2, 'total votes should match total delegated stake');
        operatorManager.announceOperatorUndelegation();
        assertEq(
            operatorManager.getVotes(operator),
            DEFAULT_AMOUNT,
            'votes should decrease by entire stake on undelegation announcement'
        );
        assertTotalVotes(DEFAULT_AMOUNT, 'total votes should decrease by entire stake on undelegation announcement');
    }

    function test_shouldNotDecreaseSlashableStakeOnUndelegationAnnouncement() public {
        operatorManager.stake(DEFAULT_AMOUNT);
        operatorManager.delegate(operator);
        assertEq(operatorManager.slashableOperatorStake(operator), DEFAULT_AMOUNT, 'slashable stake should match stake');
        operatorManager.announceOperatorUndelegation();
        assertEq(
            operatorManager.slashableOperatorStake(operator),
            DEFAULT_AMOUNT,
            'slashable stake should not decrease on undelegation announcement'
        );
    }

    function test_shouldNotBeAbleToUndelegateWhileNotDelegated() public {
        vm.expectRevert(abi.encodeWithSelector(IOperatorManager.NoOperatorSelected.selector));
        operatorManager.delegate(address(0));
    }

    function test_shouldNotBeAbleToAnnounceUndelegationWhileUndelegated() public {
        vm.expectRevert(abi.encodeWithSelector(IOperatorManager.NoOperatorSelected.selector));
        operatorManager.announceOperatorUndelegation();
    }

    function test_RevertIf_tryingToUndelegateWhileUndelegationIsPending() public {
        operatorManager.delegate(operator);
        operatorManager.announceOperatorUndelegation();
        vm.expectRevert(abi.encodeWithSelector(IOperatorManager.UndelegationNotFinalized.selector, block.timestamp));
        operatorManager.announceOperatorUndelegation();
    }

    function test_shouldNotBeAbleToUndelegateWhileUndelegationIsPending() public {
        operatorManager.updateWithdrawalDelay(1);
        operatorManager.delegate(operator);
        operatorManager.announceOperatorUndelegation();
        vm.expectRevert(abi.encodeWithSelector(IOperatorManager.UndelegationNotFinalized.selector, block.timestamp + 1));
        operatorManager.delegate(address(0));
    }

    function test_shouldNotDecreaseVotesOnUndelegation() public {
        operatorManager.stake(DEFAULT_AMOUNT);
        operatorManager.delegate(operator);
        vm.startPrank(delegator);
        operatorManager.stake(DEFAULT_AMOUNT);
        operatorManager.delegate(operator);
        assertEq(
            operatorManager.getVotes(operator), DEFAULT_AMOUNT * 2, 'initial votes should match total delegated stake'
        );
        assertTotalVotes(DEFAULT_AMOUNT * 2, 'total votes should match total delegated stake');
        operatorManager.announceOperatorUndelegation();
        assertEq(
            operatorManager.getVotes(operator),
            DEFAULT_AMOUNT,
            'votes should decrease by entire stake on undelegation announcement'
        );
        operatorManager.delegate(address(0));
        assertEq(operatorManager.getVotes(operator), DEFAULT_AMOUNT, 'votes should not decrease on undelegation');
        assertTotalVotes(DEFAULT_AMOUNT, 'total votes should not decrease on undelegation');
    }

    function test_shouldDecreaseSlashableStakeOnUndelegation() public {
        operatorManager.stake(DEFAULT_AMOUNT);
        operatorManager.delegate(operator);
        vm.startPrank(delegator);
        operatorManager.stake(DEFAULT_AMOUNT);
        operatorManager.delegate(operator);
        assertEq(
            operatorManager.slashableOperatorStake(operator),
            DEFAULT_AMOUNT * 2,
            'slashable stake should match total delegated stake'
        );
        operatorManager.announceOperatorUndelegation();
        assertEq(
            operatorManager.slashableOperatorStake(operator),
            DEFAULT_AMOUNT * 2,
            'slashable stake should not decrease on undelegation announcement'
        );
        operatorManager.delegate(address(0));
        assertEq(
            operatorManager.slashableOperatorStake(operator),
            DEFAULT_AMOUNT,
            'slashable stake should decrease on undelegation'
        );
    }

    function test_shouldAdjustOperatorVotesAfterSlashing(uint256 remainingPercentage) public {
        remainingPercentage = bound(remainingPercentage, 0, 1e18);
        stake(delegator, DEFAULT_AMOUNT);
        vm.prank(delegator);
        operatorManager.delegate(operator);
        stake(address(this), DEFAULT_AMOUNT);
        operatorManager.delegate(makeAddr('operatorB'));
        assertEq(operatorManager.getVotes(operator), DEFAULT_AMOUNT);
        assertTotalVotes(DEFAULT_AMOUNT * 2, 'total votes should match entire stake');
        operatorManager.slashOperatorVotes(operator, uint96(remainingPercentage));
        uint256 remainingVotes = uint256(DEFAULT_AMOUNT) * remainingPercentage / 1e18;
        assertEq(operatorManager.getVotes(operator), remainingVotes);
        assertTotalVotes(
            DEFAULT_AMOUNT + remainingVotes, 'total votes should decrease by slashed amount of the slashed operator'
        );
    }
}
