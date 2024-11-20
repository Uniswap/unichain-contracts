// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BuilderSystemTransactions} from '../src/BuilderSystemTransactions.sol';
import 'forge-std/Test.sol';

contract BuilderSystemTransactionsTest is Test {
    BuilderSystemTransactions public systemTransactions;
    address public owner = makeAddr('owner');
    address public builder1 = makeAddr('builder1');
    address public builder2 = makeAddr('builder2');
    address public nonBuilder = makeAddr('nonBuilder');

    function setUp() public {
        // Deploy contract and set up initial builders
        address[] memory initialBuilders = new address[](1);
        initialBuilders[0] = builder1;

        vm.prank(owner);
        systemTransactions = new BuilderSystemTransactions(initialBuilders);
    }

    function testAddBuilder() public {
        vm.startPrank(owner);
        systemTransactions.addBuilder(builder2);
        assertTrue(systemTransactions.builders(builder2));
        vm.stopPrank();
    }

    function testRemoveBuilder() public {
        vm.startPrank(owner);
        systemTransactions.addBuilder(builder2);
        systemTransactions.removeBuilder(builder2);
        assertFalse(systemTransactions.builders(builder2));
        vm.stopPrank();
    }

    function testIncrementFlashblockIndexSameBlock() public {
        vm.startPrank(builder1);

        // Increment flashblock index for the first time
        systemTransactions.incrementFlashblockIndex();
        assertEq(systemTransactions.getFlashblockIndex(), 0);

        // Increment again within the same block
        systemTransactions.incrementFlashblockIndex();
        assertEq(systemTransactions.getFlashblockIndex(), 1);

        vm.stopPrank();
    }

    function testIncrementFlashblockIndexNewBlock() public {
        vm.startPrank(builder1);

        // Increment flashblock index for the first time
        systemTransactions.incrementFlashblockIndex();
        assertEq(systemTransactions.getFlashblockIndex(), 0);

        // Roll to a new block
        vm.roll(block.number + 1);

        // Increment in a new block should reset the flashblock index
        systemTransactions.incrementFlashblockIndex();
        assertEq(systemTransactions.getFlashblockIndex(), 0);

        vm.stopPrank();
    }

    function testUnauthorizedAccessToIncrementFlashblockIndex() public {
        vm.prank(nonBuilder);
        vm.expectRevert(BuilderSystemTransactions.Unauthorized.selector);
        systemTransactions.incrementFlashblockIndex();
    }

    function testUnauthorizedAccessToAddBuilder() public {
        vm.prank(nonBuilder);
        vm.expectRevert('UNAUTHORIZED');
        systemTransactions.addBuilder(builder2);
    }

    function testUnauthorizedAccessToRemoveBuilder() public {
        vm.startPrank(owner);
        systemTransactions.addBuilder(builder2);
        vm.stopPrank();

        vm.prank(nonBuilder);
        vm.expectRevert('UNAUTHORIZED');
        systemTransactions.removeBuilder(builder2);
    }
}
