// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IBaseService, IDelegatorClaim, IL2StakeTable, IStakeTable} from '../../interfaces/UVN/L2/IL2StakeTable.sol';
import {DefaultDelegatorClaim} from './DefaultDelegatorClaim.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';
import {EIP712, Votes} from '@openzeppelin/contracts/governance/utils/Votes.sol';

/// @title L2StakeTable - Clone of the L1 stake table
/// @notice This contract is a clone of the L1 stake table. Whenever the balance of an operator changes on L1, this contract is notified and the balance is updated on L2. This contract deploys a default contract for delegators to claim rewards when the ERC-721 token is deposited on L1. This contract is then notified of subsequent stake changes on L1. Operators can override the default delegator claim contract with a custom implementation to distribute rewards differently.
contract L2StakeTable is IL2StakeTable, Votes {
    uint256 private constant MIN_DELEGATOR_UPDATE_GAS = 200_000;
    uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
    address public immutable L1_STAKE_TABLE_SYNC;

    mapping(address operator => IDelegatorClaim delegatorClaim) internal _delegatorClaims;

    modifier onlyL1StakeTableSync() {
        if (msg.sender != L1_STAKE_TABLE_SYNC) revert NotStakeTableSync();
        _;
    }

    /// @dev The contract needs to be deployed via create3 to make the address deterministic and not dependent on the l1 stake table sync address
    /// @dev The address offset needs to be applied to the l1 stake table sync address
    constructor(address l1StakeTableSync) EIP712('L2StakeTable', '1') {
        L1_STAKE_TABLE_SYNC = l1StakeTableSync;
    }

    /// @inheritdoc IBaseService
    /// @dev Only callable by the L1 stake table sync contract
    /// @dev Called by the L1 stake table sync contract when an operator's stake changes
    /// @dev Updates the operator's voting units
    /// @dev Notifies delegator claim contracts of delegator stake changes
    /// @dev Should an operator already have delegators when depositing their ERC-721 token, the balances of existing delegators need to be synced manually
    function reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
        external
        onlyL1StakeTableSync
    {
        int256 currentVotes = int256(getVotes(operator));
        // @audit newBalance can never overflow int256
        int256 newVotes = int256(newBalance);
        int256 delta = newVotes - currentVotes;
        if (delta > 0) {
            _transferVotingUnits(address(0), operator, uint256(delta));
        } else if (delta < 0) {
            _transferVotingUnits(operator, address(0), uint256(-delta));
        }
        if (delegator == address(0) && address(_delegatorClaims[operator]) == address(0)) {
            // when an ERC-721 token is deposited, delegator is address(0) in the notification
            IDelegatorClaim delegatorClaim = new DefaultDelegatorClaim(operator);
            _setDelegatorClaimContract(operator, delegatorClaim);
        }
        if (delegator != address(0)) {
            IDelegatorClaim delegatorClaim = _delegatorClaims[operator];
            // @audit a failing delegator stake update should not revert the operator stake update
            try delegatorClaim.reportDelegatorStake{gas: MIN_DELEGATOR_UPDATE_GAS}(delegator, newDelegatorStake) {}
            catch {
                emit DelegatorStakeUpdateFailed(operator, delegator);
            }
        }
    }

    /// @inheritdoc IBaseService
    /// @dev Only callable by the L1 stake table sync contract
    /// @dev Called by the L1 stake table sync contract when an operator is slashed
    /// @dev Updates the operator's voting units according to the remaining percentage of the stake
    function reportOperatorSlash(address operator, uint256 remainingPercentage) external onlyL1StakeTableSync {
        uint256 currentVotes = getVotes(operator);
        uint256 newVotes = (currentVotes * remainingPercentage) / PERCENTAGE_DENOMINATOR;
        uint256 delta = currentVotes - newVotes;
        _transferVotingUnits(operator, address(0), delta);
    }

    /// @inheritdoc IBaseService
    /// @dev Only callable by the L1 stake table sync contract
    /// @dev Called by the L1 stake table sync contract when an operator withdraws their ERC-721 token
    /// @dev Sets the operator's voting units to 0
    function onWithdrawal(address operator) external onlyL1StakeTableSync {
        uint256 currentVotes = getVotes(operator);
        _transferVotingUnits(operator, address(0), currentVotes);
    }

    /// @inheritdoc IL2StakeTable
    function overrideDelegatorClaimContract(IDelegatorClaim delegatorClaim) external {
        _setDelegatorClaimContract(msg.sender, delegatorClaim);
    }

    /// @inheritdoc IStakeTable
    function beneficiary(address operator) external view override returns (address) {
        return address(_delegatorClaims[operator]);
    }

    /// @dev Sets a delegator claim contract for an operator
    function _setDelegatorClaimContract(address operator, IDelegatorClaim delegatorClaim) internal {
        _delegatorClaims[operator] = delegatorClaim;
        emit DelegatorClaimContractSet(operator, delegatorClaim);
    }

    // VOTES OVERRIDES

    /// @dev Disable delegation
    function delegate(address) public pure override(Votes, IVotes) {
        revert DelegationDisabled();
    }

    /// @dev Disable delegation
    function delegateBySig(address, uint256, uint256, uint8, bytes32, bytes32) public pure override(Votes, IVotes) {
        revert DelegationDisabled();
    }

    /// @dev Auto delegate to self
    function delegates(address account) public view virtual override(Votes, IVotes) returns (address) {
        return account;
    }

    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return getVotes(account);
    }
}
