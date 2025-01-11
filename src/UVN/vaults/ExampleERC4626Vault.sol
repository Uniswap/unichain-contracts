// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDelegationManagerHook} from '../../interfaces/UVN/IDelegationManagerHook.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/tokens/ERC4626.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';

contract ExampleERC4626Vault is ERC4626, IDelegationManagerHook {
    address public immutable DELEGATION_MANAGER;

    error OnlyDelegationManager();
    error NonZeroBalance();

    constructor(ERC20 _asset, address _delegationManager) ERC4626(_asset, 'UVN Vault', 'UVN') {
        DELEGATION_MANAGER = _delegationManager;
    }

    modifier onlyDelegationManager() {
        if (msg.sender != DELEGATION_MANAGER) revert OnlyDelegationManager();
        _;
    }

    /// @notice Returns the total assets (ETH) in the vault
    function totalAssets() public view override returns (uint256) {
        return address(this).balance;
    }

    function beforeDelegate(address _staker, uint256 _balance) public onlyDelegationManager {}

    /// @notice Notify the vault that a staker has delegated their shares to an operator
    /// @dev The delegation manager is permissioned to mint shares to the staker
    /// @param _staker The staker that delegated their shares
    /// @param _assets The amount of assets to delegate
    function afterDelegate(address _staker, uint256 _assets) public onlyDelegationManager {
        uint256 shares = convertToShares(_assets);
        _mint(_staker, shares);

        emit Deposit(_staker, _staker, _assets, shares);
    }

    function beforeUndelegate(address _staker, uint256 _balance) public onlyDelegationManager {}

    /// @notice Notify the vault that a staker has undelegated their shares from an operator
    /// @dev The delegation manager is permissioned to burn shares from the staker
    /// @param _staker The staker that undelegated their shares
    /// @param _assets The amount of assets to undelegate
    function afterUndelegate(address _staker, uint256 _assets) public onlyDelegationManager {
        uint256 shares = convertToShares(_assets);

        _burn(_staker, shares);

        emit Withdraw(_staker, _staker, _staker, _assets, shares);

        SafeTransferLib.safeTransferETH(_staker, _assets);
    }

    /// @notice Redeem shares for assets
    /// @dev This function is overridden to transfer ETH instead of the underlying ERC20 asset
    ///      and to not call the beforeWithdraw hook
    /// @param shares The amount of shares to redeem
    /// @param receiver The address to receive the assets
    /// @param owner The owner of the shares
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, 'ZERO_ASSETS');

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        SafeTransferLib.safeTransferETH(receiver, assets);
    }

    /// @notice Revert on standard deposits
    function afterDeposit(uint256 _assets, uint256 _shares) internal override {
        if (msg.sender != DELEGATION_MANAGER) revert OnlyDelegationManager();
    }

    /// @notice Revert on standard withdrawals
    function beforeWithdraw(uint256 _assets, uint256 _shares) internal override {
        if (msg.sender != DELEGATION_MANAGER) revert OnlyDelegationManager();
    }

    /// @notice Revert on standard transfers
    function transfer(address to, uint256 amount) public override returns (bool) {
        revert('Not implemented');
    }

    receive() external payable {}
}
