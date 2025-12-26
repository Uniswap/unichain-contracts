// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import 'forge-std/Test.sol';

import {NetFeeSplitter} from '../../../src/FeeSplitter/NetFeeSplitter.sol';
import {FeeRecipientForwarder} from '../../../src/FeeSplitter/periphery/FeeRecipientForwarder.sol';

contract UnificationE2ETest is Test {
    NetFeeSplitter constant SPLITTER = NetFeeSplitter(payable(0x4300c0D3c0D3c0D3c0D3c0D3C0D3c0d3c0D30004));
    address constant TOKEN_JAR = 0xD576BDF6b560079a4c204f7644e556DbB19140b5;

    address constant UF_RECIPIENT = 0x3fCbACd76037534D2AAeB9a17f4e631dd64fbe31;
    address constant UF_SETTER = 0x3fCbACd76037534D2AAeB9a17f4e631dd64fbe31;

    address constant UL_RECIPIENT = 0xB967308F7D81035a1Cc91234A898F2655Be3f835;
    address constant UL_SETTER = 0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2;

    address constant TIMELOCK_ALIASED = 0x2BAD8182C09F50c8318d769245beA52C32Be46CD;

    FeeRecipientForwarder constant FORWARDER =
        FeeRecipientForwarder(payable(0x7A6f67B6042Ca34B01E0DeC6FeaD644CD3b8C235));

    bool forked;

    function setUp() public {
        try vm.envString('UNICHAIN_RPC_URL') returns (string memory rpcUrl) {
            console2.log('Forked Unichain');
            vm.createSelectFork(rpcUrl, 36_000_000);

            forked = true;
        } catch {
            console2.log(
                'Skipping forked tests, no unichain rpc url found. Add UNICHAIN_RPC_URL env var to .env to run forked tests.'
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

    function test_ShouldBeCorrectAliasedTimeLock() public pure {
        address timelockMainnet = 0x1a9C8182C09F50C8318d769245beA52c32BE35BC;
        address expectedAliasedTimelock =
            address(uint160(timelockMainnet) + uint160(0x1111000000000000000000000000000000001111));
        assertEq(TIMELOCK_ALIASED, expectedAliasedTimelock);
    }

    function test_PostUnificationMigrationE2E() public onlyForked {
        // test current setup
        assertEq(SPLITTER.setterOf(UF_RECIPIENT), UF_SETTER);
        assertEq(SPLITTER.setterOf(UL_RECIPIENT), UL_SETTER);
        assertEq(SPLITTER.balanceOf(UF_RECIPIENT), 7600);
        assertEq(SPLITTER.balanceOf(UL_RECIPIENT), 2400);

        uint256 earnedFeesUF = SPLITTER.earnedFees(UF_RECIPIENT);
        uint256 earnedFeesUL = SPLITTER.earnedFees(UL_RECIPIENT);

        // Unification migration:
        // 1. Uniswap Labs transfers their allocation with the aliased timelock as the setter and the forwarder as the recipient
        vm.prank(UL_SETTER);
        SPLITTER.transferAllocationAndSetSetter(UL_RECIPIENT, address(FORWARDER), TIMELOCK_ALIASED, 2400);

        // 2. Uniswap Foundation transfers their allocation to the forwarder as the recipient (timelock is already set as the setter and cannot be changed or set again)
        vm.prank(UF_SETTER);
        SPLITTER.transferAllocation(UF_RECIPIENT, address(FORWARDER), 7600);

        // The forwarder should now have the entire allocation
        assertEq(SPLITTER.balanceOf(address(FORWARDER)), 10_000);
        // The aliased timelock should be the setter of the forwarder
        assertEq(SPLITTER.setterOf(address(FORWARDER)), TIMELOCK_ALIASED);
        // The forwarder currently has no earned fees
        assertEq(SPLITTER.earnedFees(address(FORWARDER)), 0);

        // The fees of the Uniswap Foundation and Uniswap Labs should still be the same as before the migration
        assertEq(SPLITTER.earnedFees(UF_RECIPIENT), earnedFeesUF);
        assertEq(SPLITTER.earnedFees(UL_RECIPIENT), earnedFeesUL);

        // Fees sent to the net fee splitter should now be entirely earned by the forwarder
        (bool success,) = address(SPLITTER).call{value: 1 ether}('');
        assertTrue(success);
        assertEq(SPLITTER.earnedFees(address(FORWARDER)), 1 ether);
        assertEq(SPLITTER.earnedFees(UF_RECIPIENT), earnedFeesUF);
        assertEq(SPLITTER.earnedFees(UL_RECIPIENT), earnedFeesUL);

        // Calling withdraw on the forwarder should send the fees to the token jar
        FORWARDER.withdraw();
        assertEq(TOKEN_JAR.balance, 1 ether);
        assertEq(SPLITTER.earnedFees(address(FORWARDER)), 0);
        assertEq(SPLITTER.earnedFees(UF_RECIPIENT), earnedFeesUF);
        assertEq(SPLITTER.earnedFees(UL_RECIPIENT), earnedFeesUL);

        // UL and UF can still withdraw their accrued fees
        uint256 ulBalanceBefore = UL_RECIPIENT.balance;
        vm.prank(UL_RECIPIENT);
        SPLITTER.withdrawFees(UL_RECIPIENT);
        assertEq(UL_RECIPIENT.balance, ulBalanceBefore + earnedFeesUL);
        assertEq(SPLITTER.earnedFees(UL_RECIPIENT), 0);

        uint256 ufBalanceBefore = UF_RECIPIENT.balance;
        vm.prank(UF_RECIPIENT);
        SPLITTER.withdrawFees(UF_RECIPIENT);
        assertEq(UF_RECIPIENT.balance, ufBalanceBefore + earnedFeesUF);
        assertEq(SPLITTER.earnedFees(UF_RECIPIENT), 0);
    }
}
