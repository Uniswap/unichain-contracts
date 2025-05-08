// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DelegatorAccessControl} from '../../../../src/UVN/L1/StakingMiddleware/DelegatorAccessControl.sol';

import {OperatorManager} from '../../../../src/UVN/L1/StakingMiddleware/OperatorManager.sol';
import {UniStakerWrapper} from '../../../../src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol';
import {IUniStaker} from '../../../../src/interfaces/UVN/L1/IUnistaker.sol';
import {IDelegatorAccessControl} from '../../../../src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol';
import {IDelegatorVerifier} from '../../../../src/interfaces/UVN/L1/StakingMiddleware/IDelegatorVerifier.sol';
import {IOperatorManager} from '../../../../src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import {L1TestHandler} from '../L1TestHandler.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';

// Mock implementation of IDelegatorVerifier for testing
contract MockDelegatorVerifier is IDelegatorVerifier {
    mapping(address => bool) private _allowedDelegators;

    function setAllowDelegation(address delegator, bool allowed) external {
        _allowedDelegators[delegator] = allowed;
    }

    function allowDelegation(address delegator) external view override returns (bool) {
        return _allowedDelegators[delegator];
    }
}

// Concrete implementation of DelegatorAccessControl for testing
contract DelegatorAccessControlHarness is DelegatorAccessControl {
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

    // Expose internal functions for testing
    function allowDelegation(address delegator, address operator) external view returns (bool) {
        return _allowDelegation(delegator, operator);
    }
}

contract DelegatorAccessControlTest is L1TestHandler {
    string private NAME = 'UVN Staking Middleware';

    DelegatorAccessControlHarness delegatorAccessControlHarness;
    DelegatorAccessControl delegatorAccessControl;
    MockDelegatorVerifier mockVerifier;

    address operatorA;
    address operatorB;
    address delegatorA;
    address delegatorB;
    address authorizedSender;
    uint256 delegatorAPk;
    uint256 delegatorBPk;

    function setUp() public override {
        super.setUp();

        // Deploy the harness
        delegatorAccessControlHarness = new DelegatorAccessControlHarness(
            NAME,
            unistaker,
            address(this),
            7 days, // withdrawal delay
            slashingBeneficiary
        );

        // Deploy the direct implementation
        delegatorAccessControl = delegatorAccessControlHarness;

        // Deploy the mock verifier
        mockVerifier = new MockDelegatorVerifier();

        // Set up test addresses
        operatorA = makeAddr('operatorA');
        operatorB = makeAddr('operatorB');
        (delegatorA, delegatorAPk) = makeAddrAndKey('delegatorA');
        (delegatorB, delegatorBPk) = makeAddrAndKey('delegatorB');
        authorizedSender = makeAddr('authorizedSender');

        // Mint tokens for testing
        stakeToken.mint(delegatorA, 1000 ether);
        stakeToken.mint(delegatorB, 1000 ether);
        stakeToken.mint(operatorA, 1000 ether);
        stakeToken.mint(operatorB, 1000 ether);

        // Approve tokens for staking
        vm.prank(delegatorA);
        stakeToken.approve(address(delegatorAccessControl), 1000 ether);

        vm.prank(delegatorB);
        stakeToken.approve(address(delegatorAccessControl), 1000 ether);

        vm.prank(operatorA);
        stakeToken.approve(address(delegatorAccessControl), 1000 ether);

        vm.prank(operatorB);
        stakeToken.approve(address(delegatorAccessControl), 1000 ether);
    }

    // Helper function to create a valid signature for delegateBySig
    function _createSignature(uint256 privateKey, address operator_, uint256 nonce, uint256 expiry)
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
                address(delegatorAccessControl)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        return vm.sign(privateKey, digest);
    }

    // Test setting delegation status
    function test_setDelegationStatus() public {
        // Initially delegation status should be false
        assertFalse(delegatorAccessControl.delegationStatus(operatorA));

        // Set delegation status to true
        vm.prank(operatorA);
        vm.expectEmit();
        emit IDelegatorAccessControl.DelegationStatusUpdated(operatorA, true);
        delegatorAccessControl.setDelegationStatus(true);

        // Verify delegation status was updated
        assertTrue(delegatorAccessControl.delegationStatus(operatorA));
    }

    // Test setting delegation status back to false
    function test_setDelegationStatus_toFalse() public {
        // First set to true
        vm.prank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);

        // Then set back to false
        vm.prank(operatorA);
        vm.expectEmit();
        emit IDelegatorAccessControl.DelegationStatusUpdated(operatorA, false);
        delegatorAccessControl.setDelegationStatus(false);

        // Verify delegation status was updated
        assertFalse(delegatorAccessControl.delegationStatus(operatorA));
    }

    // Test setting delegation verifier
    function test_setDelegationVerifier() public {
        // Initially delegation verifier should be address(0)
        assertEq(address(delegatorAccessControl.delegationVerifier(operatorA)), address(0));

        // Set delegation verifier
        vm.prank(operatorA);
        vm.expectEmit();
        emit IDelegatorAccessControl.DelegationVerifierUpdated(operatorA, mockVerifier);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);

        // Verify delegation verifier was updated
        assertEq(address(delegatorAccessControl.delegationVerifier(operatorA)), address(mockVerifier));
    }

    // Test setting authorized sender
    function test_setAuthorizedSender() public {
        // Initially authorized sender should be address(0)
        assertEq(delegatorAccessControl.authorizedSender(operatorA), address(0));

        // Set authorized sender
        vm.prank(operatorA);
        vm.expectEmit();
        emit IDelegatorAccessControl.AuthorizedSenderUpdated(operatorA, authorizedSender);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);

        // Verify authorized sender was updated
        assertEq(delegatorAccessControl.authorizedSender(operatorA), authorizedSender);
    }

    // Test self-delegation is always allowed
    function test_selfDelegationAlwaysAllowed() public {
        // Operator stakes and self-delegates
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.delegate(operatorA);
        vm.stopPrank();

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(operatorA), operatorA);
    }

    // Test self-delegation is allowed even when delegation status is false
    function test_selfDelegationAllowedWhenStatusFalse() public {
        // Operator stakes, explicitly sets delegation status to false, and self-delegates
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(false);
        delegatorAccessControl.delegate(operatorA);
        vm.stopPrank();

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(operatorA), operatorA);
    }

    // Test delegation when operator doesn't accept delegation
    function test_delegationDisallowedWhenNotAccepted() public {
        // Operator stakes but doesn't accept delegation
        vm.prank(operatorA);
        delegatorAccessControl.stake(100 ether);

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Attempt to delegate to operator should fail
        vm.prank(delegatorA);
        vm.expectRevert(IDelegatorAccessControl.DelegationDisallowed.selector);
        delegatorAccessControl.delegate(operatorA);
    }

    // Test delegation when operator accepts delegation
    function test_delegationAllowedWhenAccepted() public {
        // Operator stakes and accepts delegation
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        vm.stopPrank();

        // Delegator stakes and delegates
        vm.startPrank(delegatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.delegate(operatorA);
        vm.stopPrank();

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorA);
    }

    // Test delegation with verifier that allows delegation
    function test_delegationAllowedWithVerifier() public {
        // Operator stakes, accepts delegation, and sets verifier
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        // Allow delegation for delegatorA
        mockVerifier.setAllowDelegation(delegatorA, true);

        // Delegator stakes and delegates
        vm.startPrank(delegatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.delegate(operatorA);
        vm.stopPrank();

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorA);
    }

    // Test delegation with verifier that disallows delegation
    function test_delegationDisallowedWithVerifier() public {
        // Operator stakes, accepts delegation, and sets verifier
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Attempt to delegate should fail because verifier returns false by default
        vm.prank(delegatorA);
        vm.expectRevert(IDelegatorAccessControl.DelegationDisallowed.selector);
        delegatorAccessControl.delegate(operatorA);
    }

    // Test delegation with authorized sender
    function test_delegationWithAuthorizedSender() public {
        // Operator stakes, accepts delegation, and sets authorized sender
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Attempt to delegate directly should fail
        vm.prank(delegatorA);
        vm.expectRevert(IDelegatorAccessControl.DelegationDisallowed.selector);
        delegatorAccessControl.delegate(operatorA);

        // Create a valid signature for delegation
        uint256 nonce = 0;
        uint256 expiry = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _createSignature(delegatorAPk, operatorA, nonce, expiry);

        // Delegation through authorized sender should succeed
        vm.prank(authorizedSender);
        delegatorAccessControl.delegateBySig(operatorA, nonce, expiry, v, r, s);

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorA);
    }

    // Test delegation with authorized sender and invalid signature
    function test_delegationWithAuthorizedSender_invalidSignature() public {
        // Operator stakes, accepts delegation, and sets authorized sender
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Create a signature using the wrong private key (delegatorB's key)
        uint256 nonce = 0;
        uint256 expiry = block.timestamp + 1 hours;

        assertNotEq(delegatorBPk, delegatorAPk);

        (uint8 v, bytes32 r, bytes32 s) = _createSignature(
            delegatorBPk, // Wrong private key
            operatorA,
            nonce,
            expiry
        );

        // Store the current delegate for delegatorA
        address initialDelegate = delegatorAccessControl.delegates(delegatorA);

        // Delegation should not change the delegate for delegatorA since the signature
        // is from delegatorB, so it will recover delegatorB's address
        vm.prank(authorizedSender);
        delegatorAccessControl.delegateBySig(operatorA, nonce, expiry, v, r, s);

        // Verify delegation did not change for delegatorA
        assertEq(delegatorAccessControl.delegates(delegatorA), initialDelegate);
    }

    // Test delegation with authorized sender and corrupted signature
    function test_delegationWithAuthorizedSender_corruptedSignature() public {
        // Operator stakes, accepts delegation, and sets authorized sender
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Create completely invalid signature values that will cause ECDSA to fail
        uint256 nonce = 0;
        uint256 expiry = block.timestamp + 1 hours;
        uint8 v = 0; // Invalid v value
        bytes32 r = bytes32(0);
        bytes32 s = bytes32(0);

        // Delegation should fail with corrupted signature
        vm.prank(authorizedSender);
        vm.expectRevert(ECDSA.ECDSAInvalidSignature.selector);
        delegatorAccessControl.delegateBySig(operatorA, nonce, expiry, v, r, s);
    }

    // Test delegation with authorized sender fails with expired signature
    function test_delegationWithAuthorizedSender_expiredSignature() public {
        // Operator stakes, accepts delegation, and sets authorized sender
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Create a signature that's already expired
        uint256 nonce = 0;
        uint256 expiry = block.timestamp - 1; // Expired
        (uint8 v, bytes32 r, bytes32 s) = _createSignature(delegatorAPk, operatorA, nonce, expiry);

        // Delegation should fail with expired signature
        vm.prank(authorizedSender);
        vm.expectRevert(abi.encodeWithSelector(IVotes.VotesExpiredSignature.selector, expiry));
        delegatorAccessControl.delegateBySig(operatorA, nonce, expiry, v, r, s);
    }

    // Test delegation with authorized sender and verifier
    function test_delegationWithAuthorizedSenderAndVerifier() public {
        // Operator stakes, accepts delegation, sets authorized sender and verifier
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Create a valid signature for delegation
        uint256 nonce = 0;
        uint256 expiry = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _createSignature(delegatorAPk, operatorA, nonce, expiry);

        // Delegation through authorized sender should succeed regardless of verifier
        vm.prank(authorizedSender);
        delegatorAccessControl.delegateBySig(operatorA, nonce, expiry, v, r, s);

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorA);
    }

    // Test delegation with verifier when delegator is allowed
    function test_delegationWithVerifierDirectly_allowed() public {
        // Operator stakes, accepts delegation, and sets verifier
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        // Allow delegation for delegatorA
        mockVerifier.setAllowDelegation(delegatorA, true);

        // Delegator stakes and delegates
        vm.startPrank(delegatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.delegate(operatorA);
        vm.stopPrank();

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorA);
    }

    // Test delegation with authorized sender but no verifier
    function test_delegationWithAuthorizedSenderNoVerifier() public {
        // Operator stakes, accepts delegation, and sets authorized sender but no verifier
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Attempt to delegate directly should fail
        vm.prank(delegatorA);
        vm.expectRevert(IDelegatorAccessControl.DelegationDisallowed.selector);
        delegatorAccessControl.delegate(operatorA);
    }

    // Fuzz test for delegation status
    function testFuzz_setDelegationStatus(bool status) public {
        vm.prank(operatorA);
        delegatorAccessControl.setDelegationStatus(status);
        assertEq(delegatorAccessControl.delegationStatus(operatorA), status);
    }

    // Fuzz test for authorized sender
    function testFuzz_setAuthorizedSender(address sender) public {
        vm.assume(sender != address(0));

        vm.prank(operatorA);
        delegatorAccessControl.setAuthorizedSender(sender);
        assertEq(delegatorAccessControl.authorizedSender(operatorA), sender);
    }

    // Test multiple operators with different settings
    function test_multipleOperatorsWithDifferentSettings() public {
        // Set up operatorA
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        vm.stopPrank();

        // Set up operatorB with verifier
        vm.startPrank(operatorB);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        // Allow delegation to operatorB for delegatorA
        mockVerifier.setAllowDelegation(delegatorA, true);

        // Delegator stakes
        vm.prank(delegatorA);
        delegatorAccessControl.stake(100 ether);

        // Delegate to operatorA
        vm.prank(delegatorA);
        delegatorAccessControl.delegate(operatorA);
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorA);

        // Cannot delegate to operatorB while already delegated
        vm.prank(delegatorA);
        vm.expectRevert(IOperatorManager.AlreadyDelegated.selector);
        delegatorAccessControl.delegate(operatorB);

        // Undelegate from operatorA - first announce undelegation
        vm.startPrank(delegatorA);
        delegatorAccessControl.announceOperatorUndelegation();

        // Verify that delegate is now address(0) but we still need to wait for the delay
        assertEq(delegatorAccessControl.delegates(delegatorA), address(0));

        // Wait for the delay period
        vm.warp(block.timestamp + 7 days + 1);

        // cannot delegate without undelegation first
        vm.expectRevert(abi.encodeWithSelector(IOperatorManager.UndelegationNotFinalized.selector, block.timestamp - 1));
        delegatorAccessControl.delegate(operatorB);

        // Now we can delegate to operatorB
        delegatorAccessControl.delegate(address(0));
        delegatorAccessControl.delegate(operatorB);
        vm.stopPrank();

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorB);
    }

    // Test edge case: self-delegation
    function test_allowDelegation_selfDelegation() public {
        // Check via harness
        assertTrue(delegatorAccessControlHarness.allowDelegation(operatorA, operatorA));

        // Check via direct contract (should not revert)
        vm.prank(operatorA);
        delegatorAccessControl.delegate(operatorA);
    }

    // Test edge case: delegation not allowed when operator doesn't accept delegation
    function test_allowDelegation_notAccepted() public {
        // Check via harness
        assertFalse(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));

        // Check via direct contract (should revert)
        vm.prank(delegatorA);
        vm.expectRevert(IDelegatorAccessControl.DelegationDisallowed.selector);
        delegatorAccessControl.delegate(operatorA);
    }

    // Test edge case: delegation allowed when operator accepts delegation and no other restrictions
    function test_allowDelegation_accepted() public {
        // Set up operator to accept delegation
        vm.prank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);

        // Check via harness
        assertTrue(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));

        // Check via direct contract (should not revert)
        vm.prank(delegatorA);
        delegatorAccessControl.delegate(operatorA);
    }

    // Test edge case: delegation with verifier
    function test_allowDelegation_withVerifier() public {
        // Set up operator to accept delegation with verifier
        vm.startPrank(operatorA);
        delegatorAccessControl.stake(100 ether);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        // Verifier denies delegation by default
        // Check via harness
        assertFalse(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));

        // Check via direct contract (should revert)
        vm.prank(delegatorA);
        vm.expectRevert(IDelegatorAccessControl.DelegationDisallowed.selector);
        delegatorAccessControl.delegate(operatorA);

        // Allow delegation via verifier
        mockVerifier.setAllowDelegation(delegatorA, true);

        // Check via harness again
        assertTrue(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));

        // Check via direct contract (should not revert)
        vm.prank(delegatorA);
        delegatorAccessControl.delegate(operatorA);
    }

    // Test edge case: direct delegation not allowed when authorized sender is set but no verifier
    function test_allowDelegation_authorizedSenderNoVerifier() public {
        vm.startPrank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        vm.prank(delegatorA);
        assertFalse(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));
    }

    // Test edge case: delegation allowed when msg.sender is the authorized sender
    function test_allowDelegation_isAuthorizedSender() public {
        vm.startPrank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        vm.prank(authorizedSender);
        assertTrue(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));
    }

    // Test edge case: delegation not allowed when verifier returns false
    function test_allowDelegation_verifierReturnsFalse() public {
        vm.startPrank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        vm.prank(delegatorA);
        assertFalse(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));
    }

    // Test edge case: delegation allowed when verifier returns true
    function test_allowDelegation_verifierReturnsTrue() public {
        vm.startPrank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        mockVerifier.setAllowDelegation(delegatorA, true);

        vm.prank(delegatorA);
        assertTrue(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));
    }

    // Test edge case: delegation with both authorized sender and verifier
    function test_allowDelegation_authorizedSenderAndVerifier() public {
        vm.startPrank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        delegatorAccessControl.setDelegationVerifier(mockVerifier);
        vm.stopPrank();

        // Delegation through authorized sender should succeed regardless of verifier
        vm.prank(authorizedSender);
        assertTrue(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));

        // Direct delegation should use verifier
        mockVerifier.setAllowDelegation(delegatorA, true);
        vm.prank(delegatorA);
        assertTrue(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));

        mockVerifier.setAllowDelegation(delegatorA, false);
        vm.prank(delegatorA);
        assertFalse(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));
    }

    // Test edge case: direct delegation not allowed when authorized sender is set but no verifier
    function test_allowDelegation_withAuthorizedSender() public {
        // Set up operator to accept delegation with authorized sender
        vm.startPrank(operatorA);
        delegatorAccessControl.setDelegationStatus(true);
        delegatorAccessControl.setAuthorizedSender(authorizedSender);
        vm.stopPrank();

        // Check via harness - should be false for direct delegation
        assertFalse(delegatorAccessControlHarness.allowDelegation(delegatorA, operatorA));

        // Check via direct contract (should revert)
        vm.prank(delegatorA);
        vm.expectRevert(IDelegatorAccessControl.DelegationDisallowed.selector);
        delegatorAccessControl.delegate(operatorA);

        // But delegation via authorized sender should work
        uint256 nonce = 0;
        uint256 expiry = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _createSignature(delegatorAPk, operatorA, nonce, expiry);

        // Delegation via authorized sender should succeed
        vm.prank(authorizedSender);
        delegatorAccessControl.delegateBySig(operatorA, nonce, expiry, v, r, s);

        // Verify delegation was successful
        assertEq(delegatorAccessControl.delegates(delegatorA), operatorA);
    }

    // Test that internal functions cannot be directly called on the contract
    function test_internalFunctionsNotAccessible() public {
        // Verify that _allowDelegation is not accessible
        bytes memory allowDelegationCalldata =
            abi.encodeWithSignature('_allowDelegation(address,address)', delegatorA, operatorA);

        (bool success,) = address(delegatorAccessControl).call(allowDelegationCalldata);
        assertFalse(success, 'Internal function _allowDelegation should not be accessible');

        // Verify that _beforeOperatorSelection is not accessible
        bytes memory beforeOperatorSelectionCalldata =
            abi.encodeWithSignature('_beforeOperatorSelection(address,address)', delegatorA, operatorA);

        (success,) = address(delegatorAccessControl).call(beforeOperatorSelectionCalldata);
        assertFalse(success, 'Internal function _beforeOperatorSelection should not be accessible');
    }
}
