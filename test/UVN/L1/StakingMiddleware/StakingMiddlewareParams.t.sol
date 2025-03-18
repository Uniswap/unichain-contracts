// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StakingMiddlewareParams} from '../../../../src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol';
import {IStakingMiddlewareParams} from
    '../../../../src/interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol';
import {L1TestHandler} from '../L1TestHandler.sol';

contract StakingMiddlewareParamsHarness is StakingMiddlewareParams {
    constructor(address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        StakingMiddlewareParams(initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {}

    // Expose internal functions for testing if needed
    function setWithdrawalDelayInternal(uint256 withdrawalDelay_) external {
        _setWithdrawalDelay(withdrawalDelay_);
    }

    function setSlashingBeneficiaryInternal(address slashingBeneficiary_) external {
        _setSlashingBeneficiary(slashingBeneficiary_);
    }
}

contract StakingMiddlewareParamsTest is L1TestHandler {
    StakingMiddlewareParams params;
    StakingMiddlewareParamsHarness paramsHarness;
    address paramsAdmin = makeAddr('paramsAdmin');
    address paramsSetter = makeAddr('paramsSetter');
    uint256 initialWithdrawalDelay = 7 days;
    address initialSlashingBeneficiary;
    bytes32 PARAMS_SETTER_ROLE;

    function setUp() public override {
        super.setUp();
        initialSlashingBeneficiary = slashingBeneficiary;

        // Deploy the regular contract for most tests
        params = new StakingMiddlewareParams(paramsAdmin, initialWithdrawalDelay, initialSlashingBeneficiary);

        // Deploy the harness for internal function tests
        paramsHarness =
            new StakingMiddlewareParamsHarness(paramsAdmin, initialWithdrawalDelay, initialSlashingBeneficiary);

        PARAMS_SETTER_ROLE = params.PARAMS_SETTER_ROLE();

        // Grant the PARAMS_SETTER_ROLE to paramsSetter on both contracts
        vm.startPrank(paramsAdmin);
        params.grantRole(PARAMS_SETTER_ROLE, paramsSetter);
        paramsHarness.grantRole(PARAMS_SETTER_ROLE, paramsSetter);
        vm.stopPrank();
    }

    function test_constructor() public view {
        assertEq(params.withdrawalDelay(), initialWithdrawalDelay);
        assertEq(params.slashingBeneficiary(), initialSlashingBeneficiary);
        assertTrue(params.hasRole(params.DEFAULT_ADMIN_ROLE(), paramsAdmin));
    }

    function test_updateWithdrawalDelay() public {
        // Update withdrawal delay
        uint256 newWithdrawalDelay = 14 days;
        vm.prank(paramsSetter);
        params.updateWithdrawalDelay(newWithdrawalDelay);

        // Verify the withdrawal delay was updated
        assertEq(params.withdrawalDelay(), newWithdrawalDelay);
    }

    function test_updateSlashingBeneficiary() public {
        // Update slashing beneficiary
        address newSlashingBeneficiary = makeAddr('newSlashingBeneficiary');
        vm.prank(paramsSetter);
        params.updateSlashingBeneficiary(newSlashingBeneficiary);

        // Verify the slashing beneficiary was updated
        assertEq(params.slashingBeneficiary(), newSlashingBeneficiary);
    }

    function test_updateWithdrawalDelay_revertWhenNotAuthorized() public {
        // Attempt to update withdrawal delay without the PARAMS_SETTER_ROLE
        address unauthorized = makeAddr('unauthorized');
        uint256 newWithdrawalDelay = 14 days;
        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256('AccessControlUnauthorizedAccount(address,bytes32)')), unauthorized, PARAMS_SETTER_ROLE
            )
        );
        params.updateWithdrawalDelay(newWithdrawalDelay);

        // Verify the withdrawal delay was not updated
        assertEq(params.withdrawalDelay(), initialWithdrawalDelay);
    }

    function test_updateSlashingBeneficiary_revertWhenNotAuthorized() public {
        // Attempt to update slashing beneficiary without the PARAMS_SETTER_ROLE
        address unauthorized = makeAddr('unauthorized');
        address newSlashingBeneficiary = makeAddr('newSlashingBeneficiary');
        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256('AccessControlUnauthorizedAccount(address,bytes32)')), unauthorized, PARAMS_SETTER_ROLE
            )
        );
        params.updateSlashingBeneficiary(newSlashingBeneficiary);

        // Verify the slashing beneficiary was not updated
        assertEq(params.slashingBeneficiary(), initialSlashingBeneficiary);
    }

    function test_emitEventsOnUpdate() public {
        // Test withdrawal delay update event
        uint256 newWithdrawalDelay = 14 days;
        vm.expectEmit();
        emit IStakingMiddlewareParams.WithdrawalDelayUpdated(initialWithdrawalDelay, newWithdrawalDelay);
        vm.prank(paramsSetter);
        params.updateWithdrawalDelay(newWithdrawalDelay);

        // Test slashing beneficiary update event
        address newSlashingBeneficiary = makeAddr('newSlashingBeneficiary');
        vm.expectEmit();
        emit IStakingMiddlewareParams.SlashingBeneficiaryUpdated(params.slashingBeneficiary(), newSlashingBeneficiary);
        vm.prank(paramsSetter);
        params.updateSlashingBeneficiary(newSlashingBeneficiary);
    }

    function test_internalFunctions() public {
        // Test internal _setWithdrawalDelay function using the harness
        uint256 newWithdrawalDelay = 21 days;
        vm.expectEmit();
        emit IStakingMiddlewareParams.WithdrawalDelayUpdated(initialWithdrawalDelay, newWithdrawalDelay);
        paramsHarness.setWithdrawalDelayInternal(newWithdrawalDelay);
        assertEq(paramsHarness.withdrawalDelay(), newWithdrawalDelay);

        // Test internal _setSlashingBeneficiary function using the harness
        address newSlashingBeneficiary = makeAddr('anotherSlashingBeneficiary');
        vm.expectEmit();
        emit IStakingMiddlewareParams.SlashingBeneficiaryUpdated(initialSlashingBeneficiary, newSlashingBeneficiary);
        paramsHarness.setSlashingBeneficiaryInternal(newSlashingBeneficiary);
        assertEq(paramsHarness.slashingBeneficiary(), newSlashingBeneficiary);
    }

    // Fuzz test for withdrawal delay updates
    function testFuzz_updateWithdrawalDelay(uint256 newWithdrawalDelay) public {
        // Update withdrawal delay
        vm.prank(paramsSetter);
        params.updateWithdrawalDelay(newWithdrawalDelay);

        // Verify the withdrawal delay was updated
        assertEq(params.withdrawalDelay(), newWithdrawalDelay);
    }

    // Fuzz test for slashing beneficiary updates
    function testFuzz_updateSlashingBeneficiary(address newSlashingBeneficiary) public {
        // Skip the zero address as it's often a special case
        vm.assume(newSlashingBeneficiary != address(0));

        // Update slashing beneficiary
        vm.prank(paramsSetter);
        params.updateSlashingBeneficiary(newSlashingBeneficiary);

        // Verify the slashing beneficiary was updated
        assertEq(params.slashingBeneficiary(), newSlashingBeneficiary);
    }

    // Test that internal functions cannot be directly called on the contract
    function test_internalFunctionsNotAccessible() public {
        // Verify that _setWithdrawalDelay is not accessible
        bytes memory setWithdrawalDelayCalldata = abi.encodeWithSignature('_setWithdrawalDelay(uint256)', 14 days);
        (bool success,) = address(params).call(setWithdrawalDelayCalldata);
        assertFalse(success, 'Internal function _setWithdrawalDelay should not be accessible');

        // Verify that _setSlashingBeneficiary is not accessible
        bytes memory setSlashingBeneficiaryCalldata =
            abi.encodeWithSignature('_setSlashingBeneficiary(address)', makeAddr('newSlashingBeneficiary'));
        (success,) = address(params).call(setSlashingBeneficiaryCalldata);
        assertFalse(success, 'Internal function _setSlashingBeneficiary should not be accessible');
    }

    // Test that PARAMS_SETTER_ROLE is accessible via a getter
    function test_paramsSetterRoleGetter() public view {
        // Verify that PARAMS_SETTER_ROLE is accessible and matches the expected value
        bytes32 expectedRole = keccak256('PARAMS_SETTER_ROLE');
        assertEq(params.PARAMS_SETTER_ROLE(), expectedRole, 'PARAMS_SETTER_ROLE getter should return the correct value');
    }

    // Test multiple updates to parameters
    function test_multipleUpdates() public {
        // First update to withdrawal delay
        uint256 firstDelay = 14 days;
        vm.prank(paramsSetter);
        params.updateWithdrawalDelay(firstDelay);
        assertEq(params.withdrawalDelay(), firstDelay, 'First withdrawal delay update failed');

        // Second update to withdrawal delay
        uint256 secondDelay = 30 days;
        vm.prank(paramsSetter);
        params.updateWithdrawalDelay(secondDelay);
        assertEq(params.withdrawalDelay(), secondDelay, 'Second withdrawal delay update failed');

        // First update to slashing beneficiary
        address firstBeneficiary = makeAddr('firstBeneficiary');
        vm.prank(paramsSetter);
        params.updateSlashingBeneficiary(firstBeneficiary);
        assertEq(params.slashingBeneficiary(), firstBeneficiary, 'First slashing beneficiary update failed');

        // Second update to slashing beneficiary
        address secondBeneficiary = makeAddr('secondBeneficiary');
        vm.prank(paramsSetter);
        params.updateSlashingBeneficiary(secondBeneficiary);
        assertEq(params.slashingBeneficiary(), secondBeneficiary, 'Second slashing beneficiary update failed');

        // Verify events are emitted correctly on multiple updates
        uint256 thirdDelay = 60 days;
        vm.expectEmit();
        emit IStakingMiddlewareParams.WithdrawalDelayUpdated(secondDelay, thirdDelay);
        vm.prank(paramsSetter);
        params.updateWithdrawalDelay(thirdDelay);

        address thirdBeneficiary = makeAddr('thirdBeneficiary');
        vm.expectEmit();
        emit IStakingMiddlewareParams.SlashingBeneficiaryUpdated(secondBeneficiary, thirdBeneficiary);
        vm.prank(paramsSetter);
        params.updateSlashingBeneficiary(thirdBeneficiary);
    }
}
