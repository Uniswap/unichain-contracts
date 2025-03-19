// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IService, IStakeTableSync} from '../../interfaces/UVN/L1/IStakeTableSync.sol';
import {IStakingMiddleware} from '../../interfaces/UVN/L1/IStakingMiddleware.sol';
import {IBaseService} from '../../interfaces/UVN/interfaces/IBaseService.sol';
import {OperatorTokenLib} from './StakingMiddleware/libraries/OperatorTokenLib.sol';
import {IOptimismPortal2} from '@eth-optimism-bedrock/src/L1/interfaces/IOptimismPortal2.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {ERC165, IERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/// @title StakeTableSync
/// @notice This contract is used to sync the stake table of the StakingMiddleware contract to the L2. On notifications about slashing and balance changes from the StakingMiddleware, the data is forwarded to the StakeTable contract on L2. On deposits of operator ERC-721 tokens, the initial balance of the operator is reported to the StakeTable contract on L2. Should an operator already have delegators before depositing their operator token or should they withdraw their operator token and re-deposit it, inconsistencies in the stake of individual delegators could occur. This contract exposes two sync functions to forcefully sync the correct balances to L2.
contract StakeTableSync is IStakeTableSync, ERC165 {
    IOptimismPortal2 public constant OPTIMISM_PORTAL =
        IOptimismPortal2(payable(0xe2F826324b2faf99E513D16D266c3F80aE87832B));
    IStakingMiddleware public immutable STAKING_MIDDLEWARE;
    address public immutable L2_STAKE_TABLE;

    modifier onlyStakingMiddleware() {
        if (msg.sender != address(STAKING_MIDDLEWARE)) revert NotStakingMiddleware();
        _;
    }

    constructor(IStakingMiddleware stakingMiddleware_) {
        STAKING_MIDDLEWARE = stakingMiddleware_;
    }

    /// @notice Reports the current stake of a delegator and their operator to L2
    /// @dev Only callable by the StakingMiddleware
    function reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
        external
        onlyStakingMiddleware
    {
        _reportOperatorStake(operator, newBalance, delegator, newDelegatorStake);
    }

    /// @notice Reports a slashing incident to L2
    /// @dev Only callable by the StakingMiddleware
    function reportOperatorSlash(address operator, uint256 remainingPercentage) external onlyStakingMiddleware {
        // TODO: measure gas cost and adjust
        uint64 gasLimit = 1_000_000;
        _depositTransaction(
            abi.encodeWithSelector(IBaseService.reportOperatorSlash.selector, operator, remainingPercentage), gasLimit
        );
    }

    /// @notice Reports a withdrawal of an operator token to L2
    function onWithdrawal(address operator) external {
        // TODO: measure gas cost and adjust
        uint64 gasLimit = 1_000_000;
        _depositTransaction(abi.encodeWithSelector(IBaseService.onWithdrawal.selector, operator), gasLimit);
    }

    /// @inheritdoc IStakeTableSync
    function sync(address delegator) external {
        address operator = STAKING_MIDDLEWARE.delegates(delegator);
        uint256 operatorBalance = STAKING_MIDDLEWARE.getVotes(operator);
        uint256 delegatorBalance = STAKING_MIDDLEWARE.delegatorStake(delegator);
        _reportOperatorStake(operator, operatorBalance, delegator, delegatorBalance);
    }

    /// @inheritdoc IStakeTableSync
    function syncOperator(address operator) public {
        uint256 operatorBalance = STAKING_MIDDLEWARE.getVotes(operator);
        // TODO: deploy delegation reward distribution contract on L2 when operator is first deposited, provide higher gas limit here
        uint64 gasLimit = 5_000_000;
        _reportOperatorStake(operator, operatorBalance, address(0), 0, gasLimit);
    }

    /// @notice Called when an operator ERC-721 token is deposited
    /// @dev Reports the initial balance of the operator to L2
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        address operator = OperatorTokenLib.toAddress(tokenId);
        syncOperator(operator);
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IService).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Reports the current stake of a delegator and their operator to L2 with a default gas limit
    function _reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
        internal
    {
        // TODO: measure gas cost and adjust
        // L1 gas is burned to prevent spam on L2
        // Consider edge cases with high gas costs on L2
        uint64 gasLimit = 1_000_000;
        _reportOperatorStake(operator, newBalance, delegator, newDelegatorStake, gasLimit);
    }

    /// @notice Reports the current stake of a delegator and their operator to L2 with a custom gas limit
    function _reportOperatorStake(
        address operator,
        uint256 newBalance,
        address delegator,
        uint256 newDelegatorStake,
        uint64 gasLimit
    ) internal {
        _depositTransaction(
            abi.encodeWithSelector(
                IBaseService.reportOperatorStake.selector, operator, newBalance, delegator, newDelegatorStake
            ),
            gasLimit
        );
    }

    /// @notice Sends a transaction to the L2 StakeTable contract
    function _depositTransaction(bytes memory data, uint64 gasLimit) internal {
        OPTIMISM_PORTAL.depositTransaction(L2_STAKE_TABLE, 0, gasLimit, false, data);
    }
}
