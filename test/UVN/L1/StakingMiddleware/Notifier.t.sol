// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {INotifier, Notifier} from '../../../../src/UVN/L1/StakingMiddleware/Notifier.sol';

import {IUniStaker, UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {IBaseService} from '../../../../src/interfaces/UVN/IBaseService.sol';
import {
    EmptyContract,
    InfiniteLoopServiceContract,
    MaliciousServiceContract,
    MockServiceContract,
    NonServiceERC165Contract,
    RevertDataBombServiceContract,
    RevertingServiceContract
} from '../../../mock/MockServiceContracts.sol';
import {L1TestHandler} from '../L1TestHandler.sol';
import {IERC721Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract NotifierHarness is Notifier {
    constructor(IUniStaker unistaker_, address initialAdmin, address slashingBeneficiary_)
        UniStakerWrapper(unistaker_, initialAdmin, 0, slashingBeneficiary_)
        Notifier('UVN Staking Middleware', 'UVN')
    {}

    function reportOperatorStakeUpdate(
        address operator,
        uint96 operatorStake,
        address delegator,
        uint96 delegatorStake_,
        bool requireSuccess
    ) public {
        _reportOperatorStakeUpdate(operator, operatorStake, delegator, delegatorStake_, requireSuccess);
    }

    function reportOperatorSlash(address operator, uint256 remainingPercentage) public {
        _reportOperatorSlash(operator, remainingPercentage);
    }

    function isAuthorized(address owner, address spender, uint256 tokenId) public view returns (bool) {
        return _isAuthorized(owner, spender, tokenId);
    }

    function isServiceContract(address account) public view returns (bool) {
        return _isServiceContract(account);
    }
}

contract StakingMiddlewareSlashingTest is L1TestHandler {
    uint96 private constant DEFAULT_AMOUNT = 1000;

    NotifierHarness notifier;
    MockServiceContract serviceContract;
    MockServiceContract serviceContract2;
    RevertingServiceContract revertingServiceContract;
    EmptyContract emptyContract;
    NonServiceERC165Contract nonServiceERC165Contract;
    MaliciousServiceContract maliciousServiceContract;
    InfiniteLoopServiceContract infiniteLoopServiceContract;
    RevertDataBombServiceContract revertDataBombServiceContract;

    address private delegator2 = makeAddr('delegator2');

    function setUp() public override {
        super.setUp();
        notifier = new NotifierHarness(unistaker, address(this), slashingBeneficiary);
        notifier.grantRole(notifier.SLASHER_ROLE(), slasher);
        unistaker.setRewardNotifier(address(this), true);
        unistaker.stake(0, operator);
        serviceContract = new MockServiceContract(notifier);
        serviceContract2 = new MockServiceContract(notifier);
        revertingServiceContract = new RevertingServiceContract();
        emptyContract = new EmptyContract();
        nonServiceERC165Contract = new NonServiceERC165Contract();
        maliciousServiceContract = new MaliciousServiceContract();
        infiniteLoopServiceContract = new InfiniteLoopServiceContract();
        revertDataBombServiceContract = new RevertDataBombServiceContract();
    }

    function deposit(address user, uint96 amount) internal {
        stakeToken.mint(user, amount);
        vm.startPrank(user);
        stakeToken.approve(address(notifier), amount);
        notifier.stake(amount);
        vm.stopPrank();
    }

    function depositAndDelegate(address user, uint96 amount) internal {
        deposit(user, amount);
        vm.prank(operator);
        notifier.setDelegationStatus(true);
        vm.prank(user);
        notifier.delegate(operator);
    }

    function depositNFT() internal {
        depositNFT(address(serviceContract));
    }

    function depositNFT(address serviceContract_) internal {
        vm.startPrank(operator);
        notifier.mint();
        notifier.safeTransferFrom(operator, address(serviceContract_), toId(operator));
        vm.stopPrank();
    }

    function slashOperator() internal {
        vm.prank(slasher);
        notifier.slashPercentage(operator, 1);
    }

    function toId(address operator_) internal pure returns (uint256) {
        return uint256(uint160(operator_));
    }

    function test_ShouldBeAbleToMintNFT(address operator_) public {
        if (operator_ == address(0)) return;
        uint256 expectedTokenId = toId(operator_);
        vm.prank(operator_);
        vm.expectEmit();
        emit IERC721.Transfer(address(0), operator_, expectedTokenId);
        notifier.mint();
        assertEq(notifier.balanceOf(operator_), 1, 'operator should have 1 NFT');
        assertEq(notifier.ownerOf(expectedTokenId), operator_, 'NFT should be operator');
    }

    function test_RevertIf_OperatorAlreadyHasNFTMinted(address operator_) public {
        if (operator_ == address(0)) return;
        vm.startPrank(operator_);
        notifier.mint();
        vm.expectRevert(abi.encodeWithSelector(INotifier.AlreadyMinted.selector));
        notifier.mint();
    }

    function test_RevertIf_SettingURIForNonExistentToken(address operator_) public {
        if (operator_ == address(0)) return;
        vm.startPrank(operator_);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, toId(operator_)));
        notifier.setURI('test');
    }

    function test_ShouldBeAbleToSetURI(address operator_) public {
        if (operator_ == address(0)) return;
        vm.startPrank(operator_);
        notifier.mint();
        assertEq(notifier.tokenURI(toId(operator_)), '');
        vm.expectEmit();
        emit INotifier.URIUpdated(operator_, toId(operator_), 'test');
        notifier.setURI('test');
        assertEq(notifier.tokenURI(toId(operator_)), 'test');
    }

    function test_RevertIf_UnsafeTransfer() public {
        vm.startPrank(operator);
        notifier.mint();
        vm.expectRevert(abi.encodeWithSelector(INotifier.UnsafeTransfer.selector));
        notifier.transferFrom(operator, delegator, toId(operator));
    }

    function test_ShouldBeAbleToTransferToServiceContract() public {
        vm.startPrank(operator);
        notifier.mint();
        vm.expectCall(
            address(serviceContract),
            abi.encodeWithSelector(IERC721Receiver.onERC721Received.selector, operator, operator, toId(operator), '')
        );
        vm.expectEmit();
        emit IERC721.Transfer(operator, address(serviceContract), toId(operator));
        notifier.safeTransferFrom(operator, address(serviceContract), toId(operator));
    }

    function test_ShouldBeAbleToTransferToServiceContractWithData() public {
        vm.startPrank(operator);
        notifier.mint();
        vm.expectCall(
            address(serviceContract),
            abi.encodeWithSelector(
                IERC721Receiver.onERC721Received.selector, operator, operator, toId(operator), 'data'
            )
        );
        vm.expectEmit();
        emit IERC721.Transfer(operator, address(serviceContract), toId(operator));
        notifier.safeTransferFrom(operator, address(serviceContract), toId(operator), 'data');
    }

    function test_ShouldBeAbleToTransferBackToOperator() public {
        vm.startPrank(operator);
        notifier.mint();
        notifier.safeTransferFrom(operator, address(serviceContract), toId(operator));
        vm.expectEmit();
        emit IERC721.Transfer(address(serviceContract), operator, toId(operator));
        serviceContract.transfer(operator, toId(operator));
    }

    function test_OperatorShouldBeAuthorizedToTransferOwnNFT(address operator, address owner) public view {
        assertTrue(notifier.isAuthorized(owner, operator, toId(operator)));
    }

    function test_OperatorCanForceTransferBackToSelf() public {
        vm.startPrank(operator);
        notifier.mint();
        notifier.safeTransferFrom(operator, address(serviceContract), toId(operator));
        vm.expectEmit();
        emit IERC721.Transfer(address(serviceContract), operator, toId(operator));
        notifier.safeTransferFrom(address(serviceContract), operator, toId(operator));
    }

    function test_OperatorCanForceTransferToOtherRecipient() public {
        vm.startPrank(operator);
        notifier.mint();
        notifier.safeTransferFrom(operator, address(serviceContract), toId(operator));
        vm.expectEmit();
        emit IERC721.Transfer(address(serviceContract), address(serviceContract2), toId(operator));
        notifier.safeTransferFrom(address(serviceContract), address(serviceContract2), toId(operator));
    }

    function test_RevertIf_RecipientIsEOA() public {
        vm.startPrank(operator);
        notifier.mint();
        assertFalse(notifier.isServiceContract(delegator));
        vm.expectRevert(INotifier.InvalidRecipient.selector);
        notifier.safeTransferFrom(operator, delegator, toId(operator));
    }

    function test_RevertIf_RecipientIs7702Account() public {
        address smartWallet = makeAddr('smart wallet');
        address implementation = makeAddr('implementation');
        vm.etch(smartWallet, bytes.concat(hex'ef0100', abi.encodePacked(implementation)));
        vm.startPrank(operator);
        notifier.mint();
        assertFalse(notifier.isServiceContract(smartWallet));
        vm.expectRevert(INotifier.InvalidRecipient.selector);
        notifier.safeTransferFrom(operator, smartWallet, toId(operator));
    }

    function test_RevertIf_ServiceContractDoesNotImplementERC165() public {
        vm.startPrank(operator);
        notifier.mint();
        assertFalse(notifier.isServiceContract(address(emptyContract)));
        vm.expectRevert(INotifier.InvalidRecipient.selector);
        notifier.safeTransferFrom(operator, address(emptyContract), toId(operator));
    }

    function test_RevertIf_ServiceContractERC165CheckReverts() public {
        vm.startPrank(operator);
        notifier.mint();
        assertFalse(notifier.isServiceContract(address(revertingServiceContract)));
        vm.expectRevert(INotifier.InvalidRecipient.selector);
        notifier.safeTransferFrom(operator, address(revertingServiceContract), toId(operator));
    }

    function test_RevertIf_ERC165CheckReturnsFalse() public {
        vm.startPrank(operator);
        notifier.mint();
        assertFalse(notifier.isServiceContract(address(nonServiceERC165Contract)));
        vm.expectRevert(INotifier.InvalidRecipient.selector);
        notifier.safeTransferFrom(operator, address(nonServiceERC165Contract), toId(operator));
    }

    function test_AllowTransferFromMaliciousServiceContract() public {
        vm.startPrank(operator);
        notifier.mint();
        assertTrue(notifier.isServiceContract(address(maliciousServiceContract)));
        notifier.safeTransferFrom(operator, address(maliciousServiceContract), toId(operator));
        vm.expectCall(
            address(maliciousServiceContract), abi.encodeWithSelector(IBaseService.onWithdrawal.selector, operator)
        );
        vm.expectEmit();
        emit IERC721.Transfer(address(maliciousServiceContract), operator, toId(operator));
        notifier.safeTransferFrom(address(maliciousServiceContract), operator, toId(operator));
    }

    function test_ShouldReportAfterStake() public {
        depositNFT();
        depositAndDelegate(delegator, 0);
        depositAndDelegate(delegator2, DEFAULT_AMOUNT);
        vm.prank(delegator);
        vm.expectCall(
            address(serviceContract),
            abi.encodeWithSelector(
                IBaseService.reportOperatorStake.selector,
                operator,
                DEFAULT_AMOUNT * 3 / 2,
                delegator,
                DEFAULT_AMOUNT / 2
            )
        );
        deposit(delegator, DEFAULT_AMOUNT / 2);
    }

    function test_ShouldReportAfterUnstake() public {
        depositNFT();
        depositAndDelegate(delegator, DEFAULT_AMOUNT);
        depositAndDelegate(delegator2, DEFAULT_AMOUNT);
        vm.expectCall(
            address(serviceContract),
            abi.encodeWithSelector(
                IBaseService.reportOperatorStake.selector,
                operator,
                DEFAULT_AMOUNT + DEFAULT_AMOUNT / 4,
                delegator,
                DEFAULT_AMOUNT / 4
            )
        );
        vm.prank(delegator);
        notifier.unstake(DEFAULT_AMOUNT * 3 / 4);
    }

    function test_ShouldReportAfterDelegation() public {
        depositNFT();
        deposit(delegator, DEFAULT_AMOUNT);
        depositAndDelegate(delegator2, DEFAULT_AMOUNT);
        vm.expectCall(
            address(serviceContract),
            abi.encodeWithSelector(
                IBaseService.reportOperatorStake.selector, operator, DEFAULT_AMOUNT * 2, delegator, DEFAULT_AMOUNT
            )
        );
        vm.prank(delegator);
        notifier.delegate(operator);
    }

    function test_ShouldReportAfterUndelegationAnnouncement() public {
        depositNFT();
        depositAndDelegate(delegator, DEFAULT_AMOUNT);
        depositAndDelegate(delegator2, DEFAULT_AMOUNT);
        vm.expectCall(
            address(serviceContract),
            abi.encodeWithSelector(IBaseService.reportOperatorStake.selector, operator, DEFAULT_AMOUNT, delegator, 0)
        );
        vm.prank(delegator);
        notifier.announceOperatorUndelegation();
    }

    function test_ShouldNotBeAbleToPreventUndelegationAnnouncement() public {
        depositNFT();
        depositAndDelegate(delegator, DEFAULT_AMOUNT);
        depositAndDelegate(delegator2, DEFAULT_AMOUNT);
        // transfer the NFT to a malicious service contract
        vm.prank(operator);
        notifier.safeTransferFrom(address(serviceContract), address(maliciousServiceContract), toId(operator));
        vm.expectCall(
            address(maliciousServiceContract),
            abi.encodeWithSelector(IBaseService.reportOperatorStake.selector, operator, DEFAULT_AMOUNT, delegator, 0)
        );
        vm.prank(delegator);
        notifier.announceOperatorUndelegation();
    }

    function test_TrustedServiceCanRevertOnUndelegationAnnouncement() public {
        notifier.grantRole(notifier.TRUSTED_SERVICE_ROLE(), address(maliciousServiceContract));
        depositNFT();
        depositAndDelegate(delegator, DEFAULT_AMOUNT);
        // transfer the NFT to a malicious service contract
        vm.prank(operator);
        notifier.safeTransferFrom(address(serviceContract), address(maliciousServiceContract), toId(operator));
        vm.prank(delegator);
        vm.expectRevert(
            abi.encodeWithSelector(
                INotifier.WrappedError.selector,
                maliciousServiceContract,
                IBaseService.reportOperatorStake.selector,
                '',
                abi.encodePacked(INotifier.NotificationFailed.selector)
            )
        );
        notifier.announceOperatorUndelegation();
    }

    function test_ShouldReportAfterSlash() public {
        depositNFT();
        depositAndDelegate(delegator, DEFAULT_AMOUNT);
        vm.expectCall(
            address(serviceContract), abi.encodeWithSelector(IBaseService.reportOperatorSlash.selector, operator, 1)
        );
        vm.prank(slasher);
        notifier.slashPercentage(operator, 1e18 - 1);
    }

    function test_ShouldRevertWithWrappedError() public {
        depositNFT(address(maliciousServiceContract));
        vm.expectRevert(
            abi.encodeWithSelector(
                INotifier.WrappedError.selector,
                maliciousServiceContract,
                IBaseService.reportOperatorStake.selector,
                '',
                abi.encodePacked(INotifier.NotificationFailed.selector)
            )
        );
        notifier.reportOperatorStakeUpdate(operator, DEFAULT_AMOUNT, delegator, DEFAULT_AMOUNT, true);
    }

    function test_ShouldNotBeAbleToRunOutOfGas() public {
        depositNFT(address(infiniteLoopServiceContract));
        notifier.reportOperatorStakeUpdate(operator, DEFAULT_AMOUNT, delegator, DEFAULT_AMOUNT, false);
        notifier.reportOperatorSlash(operator, 1);
    }

    function test_ShouldNotBeAbleToRevertDataBomb() public {
        depositNFT(address(revertDataBombServiceContract));
        notifier.reportOperatorStakeUpdate(operator, DEFAULT_AMOUNT, delegator, DEFAULT_AMOUNT, false);
        notifier.reportOperatorSlash(operator, 1);
    }

    function test_TrustedServiceCanRevertOnSlashing() public {
        notifier.grantRole(notifier.TRUSTED_SERVICE_ROLE(), address(maliciousServiceContract));
        depositNFT(address(maliciousServiceContract));
        vm.expectRevert(
            abi.encodeWithSelector(
                INotifier.WrappedError.selector,
                maliciousServiceContract,
                IBaseService.reportOperatorSlash.selector,
                '',
                abi.encodePacked(INotifier.NotificationFailed.selector)
            )
        );
        notifier.reportOperatorSlash(operator, 1);
    }
}
