// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IDelegationManagerHook} from '../../interfaces/UVN/IDelegationManagerHook.sol';
import {IStakeManager} from '../../interfaces/UVN/IStakeManager.sol';
import {OperatorData} from './BaseStructs.sol';

contract DelegationManager {
    IStakeManager public immutable STAKE_MANAGER;

    uint256 public constant DELEGATION_DELAY_BLOCKS = 60;

    /// @notice Thrown when the caller has already registered a vault.
    error AlreadyRegistered();
    /// @notice Thrown when the caller has already delegated to an operator.
    error AlreadyDelegated();
    /// @notice Thrown when the caller has not delegated to the operator.
    error NotDelegated();
    /// @notice Thrown when the caller has not waited the required delay since their last delegation.
    error DelegationDelay();

    /// @notice Mapping of stakers to their currently delegated operator.
    mapping(address staker => address operator) public delegatedTo;
    /// @notice Mapping of stakers to the block number at which their delegation was last updated.
    mapping(address staker => uint32 lastDelegatedAt) public lastDelegatedAt;
    /// @notice Register a vault to receive callbacks on delegate and undelegate events.
    mapping(address operator => address vault) public registeredVaults;
    /// @notice Mapping of operators to their tracked data.
    mapping(address operator => OperatorData) public operatorData;

    /// @notice The total delegated supply.
    uint256 public totalDelegatedSupply;

    constructor(address _stakeManager) {
        STAKE_MANAGER = IStakeManager(_stakeManager);
    }

    /// @notice Modifier to ensure the caller has waited the required number of blocks since their last delegation.
    modifier onlyAfterDelegationDelay(address _staker) {
        uint32 _lastDelegatedAt = lastDelegatedAt[_staker];
        if (block.number - _lastDelegatedAt < DELEGATION_DELAY_BLOCKS && _lastDelegatedAt != 0) revert DelegationDelay();
        _;
        lastDelegatedAt[_staker] = uint32(block.number);
    }

    /// Simple functions to delegate and undelegate to an operator.
    /// @dev additional checks can be added like delays, etc.
    function delegate(address _operator) external onlyAfterDelegationDelay(msg.sender) {
        uint256 balance0 = STAKE_MANAGER.balanceOf(msg.sender);
        address vault = registeredVaults[_operator];

        if (vault != address(0)) {
            IDelegationManagerHook(vault).beforeDelegate(msg.sender, balance0);
        }

        _delegate(msg.sender, _operator, uint96(balance0));

        if (vault != address(0)) {
            IDelegationManagerHook(vault).afterDelegate(msg.sender, balance0);
        }
    }

    function undelegate(address _operator) external onlyAfterDelegationDelay(msg.sender) {
        uint256 balance0 = STAKE_MANAGER.balanceOf(msg.sender);
        address vault = registeredVaults[_operator];

        if (vault != address(0)) {
            IDelegationManagerHook(vault).beforeUndelegate(msg.sender, balance0);
        }

        _undelegate(msg.sender, _operator, uint96(balance0));

        if (vault != address(0)) {
            IDelegationManagerHook(vault).afterUndelegate(msg.sender, balance0);
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
