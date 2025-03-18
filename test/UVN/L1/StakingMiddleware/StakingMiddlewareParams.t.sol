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
    StakingMiddlewareParamsHarness params;
    address paramsAdmin = makeAddr('paramsAdmin');
    address paramsSetter = makeAddr('paramsSetter');
    uint256 initialWithdrawalDelay = 7 days;
    address initialSlashingBeneficiary;
    bytes32 PARAMS_SETTER_ROLE;

    function setUp() public override {
        super.setUp();
        initialSlashingBeneficiary = slashingBeneficiary;
        params = new StakingMiddlewareParamsHarness(paramsAdmin, initialWithdrawalDelay, initialSlashingBeneficiary);
        PARAMS_SETTER_ROLE = params.PARAMS_SETTER_ROLE();

        // Grant the PARAMS_SETTER_ROLE to paramsSetter
        vm.prank(paramsAdmin);
        params.grantRole(PARAMS_SETTER_ROLE, paramsSetter);
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
        // Test internal _setWithdrawalDelay function
        uint256 newWithdrawalDelay = 21 days;
        vm.expectEmit();
        emit IStakingMiddlewareParams.WithdrawalDelayUpdated(initialWithdrawalDelay, newWithdrawalDelay);
        params.setWithdrawalDelayInternal(newWithdrawalDelay);
        assertEq(params.withdrawalDelay(), newWithdrawalDelay);

        // Test internal _setSlashingBeneficiary function
        address newSlashingBeneficiary = makeAddr('anotherSlashingBeneficiary');
        vm.expectEmit();
        emit IStakingMiddlewareParams.SlashingBeneficiaryUpdated(initialSlashingBeneficiary, newSlashingBeneficiary);
        params.setSlashingBeneficiaryInternal(newSlashingBeneficiary);
        assertEq(params.slashingBeneficiary(), newSlashingBeneficiary);
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
}
