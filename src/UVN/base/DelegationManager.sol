// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IDelegateCallback} from '../../interfaces/UVN/IDelegateCallback.sol';
import {IStakeManager} from '../../interfaces/UVN/IStakeManager.sol';
import {OperatorData} from './BaseStructs.sol';

contract DelegationManager {
    IStakeManager public immutable STAKE_MANAGER;

    /// @notice Thrown when the caller has already registered a vault.
    error AlreadyRegistered();
    /// @notice Thrown when the caller has already delegated to an operator.
    error AlreadyDelegated();
    /// @notice Thrown when the caller has not delegated to the operator.
    error NotDelegated();

    /// @notice Mapping of stakers to their currently delegated operator.
    mapping(address staker => address operator) public delegatedTo;
    /// @notice Register a vault to receive callbacks on delegate and undelegate events.
    mapping(address operator => address vault) public registeredVaults;
    /// @notice Mapping of operators to their tracked data.
    mapping(address operator => OperatorData) public operatorData;

    /// @notice The total delegated supply.
    uint256 public totalDelegatedSupply;

    constructor(address _stakeManager) {
        STAKE_MANAGER = IStakeManager(_stakeManager);
    }

    /// Simple functions to delegate and undelegate to an operator.
    /// @dev additional checks can be added like delays, etc.
    function delegate(address _operator) external {
        uint256 balance0 = STAKE_MANAGER.balanceOf(msg.sender);

        _delegate(msg.sender, _operator, uint96(balance0));

        address vault = registeredVaults[_operator];
        if (vault != address(0)) {
            IDelegateCallback(vault).notifyDelegate(msg.sender, balance0);
        }
    }

    function undelegate(address _operator) external {
        uint256 balance0 = STAKE_MANAGER.balanceOf(msg.sender);

        _undelegate(msg.sender, _operator, uint96(balance0));

        address vault = registeredVaults[_operator];
        if (vault != address(0)) {
            IDelegateCallback(vault).notifyUndelegate(msg.sender, balance0);
        }
    }

    function registerVault(address _vault) external {
        if (registeredVaults[msg.sender] != address(0)) revert AlreadyRegistered();

        registeredVaults[msg.sender] = _vault;
    }

    function _delegate(address _staker, address _operator, uint96 _balance) internal {
        if (delegatedTo[_staker] != address(0)) revert AlreadyDelegated();

        OperatorData memory _operatorData = operatorData[_operator];
        _operatorData.sharesLast = _operatorData.sharesCurrent;
        _operatorData.sharesCurrent += _balance;
        _operatorData.lastSyncedBlock = uint32(block.number);

        delegatedTo[_staker] = _operator;
        operatorData[_operator] = _operatorData;

        totalDelegatedSupply += _balance;
    }

    function _undelegate(address _staker, address _operator, uint96 _balance) internal {
        if (delegatedTo[_staker] != _operator) revert NotDelegated();

        OperatorData memory _operatorData = operatorData[_operator];
        _operatorData.sharesLast = _operatorData.sharesCurrent;
        _operatorData.sharesCurrent -= _balance;
        _operatorData.lastSyncedBlock = uint32(block.number);

        delegatedTo[_staker] = address(0);
        operatorData[_operator] = _operatorData;

        totalDelegatedSupply -= _balance;
    }
}
