// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import 'forge-std/Test.sol';

import {ExampleERC4626Vault} from '../../src/UVN/vaults/ExampleERC4626Vault.sol';

import {MockERC20} from '../mock/MockERC20.sol';
import {UVNSetupTest} from './UVNSetup.t.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';

contract ExampleERC4626VaultTest is UVNSetupTest {
    ExampleERC4626Vault public vault;
    address internal _vault;

    function setUp() public override {
        super.setUp();

        MockERC20 mockERC20 = new MockERC20();

        vault = new ExampleERC4626Vault(ERC20(address(mockERC20)), address(delegationManager));
        _vault = address(vault);
    }

    function test_TotalAssets() public {
        assertEq(vault.totalAssets(), 0);
    }

    function test_fuzz_TotalAssets(uint256 _amount) public {
        vm.deal(_vault, _amount);
        assertEq(vault.totalAssets(), _amount);
    }

    function test_notifyDelegate() public {
        vm.deal(_vault, 100);

        vm.prank(_delegationManager);
        vault.afterDelegate(alice, 100);

        assertEq(vault.balanceOf(alice), 100);
        assertEq(vault.totalAssets(), 100);
        assertEq(vault.previewRedeem(100), 100);

        uint256 balance0 = alice.balance;

        vm.prank(alice);
        vault.redeem(100, alice, alice);

        assertEq(balance0 + 100, alice.balance);
    }
}
