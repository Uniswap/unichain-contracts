// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IERC20, IUniStaker, IUniStakerWrapper
} from '../../../interfaces/UVN/L1/StakingMiddleware/IUniStakerWrapper.sol';
import {StakeManager} from './StakeManager.sol';

/// @title UniStakerWrapper - Base contract for the StakingMiddleware
/// @notice This contract manages deposits into the UniStaker contract. It allows delegators to participate in UNI governance and accrue protocol fees distributed by the UniStaker contract. The deposit into UniStaker is optional, once a delegator opts in, all subsequent deposits will also be deposited into the UniStaker contract.
contract UniStakerWrapper is StakeManager, IUniStakerWrapper {
    /// @inheritdoc IUniStakerWrapper
    IUniStaker public immutable UNISTAKER;
    /// @inheritdoc IUniStakerWrapper
    IERC20 public immutable REWARD_TOKEN;

    mapping(address delegator => uint256 depositId) private _depositIds;

    constructor(IUniStaker unistaker, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
        StakeManager(address(unistaker.STAKE_TOKEN()), initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    {
        UNISTAKER = unistaker;
        REWARD_TOKEN = IERC20(address(unistaker.REWARD_TOKEN()));
    }

    /// @dev After a delegator stakes, if they are opted into the UniStaker contract, deposit their stake into the UniStaker contract
    function _afterStake(address delegator, uint96 amount) internal virtual override {
        if (_isDepositedIntoUniStaker(delegator)) {
            _depositIntoUniStaker(amount, address(0));
        }
        super._afterStake(delegator, amount);
    }

    /// @dev Before a delegator withdraws, if they are opted into the UniStaker contract, withdraw their stake from the UniStaker contract
    function _beforeWithdraw(address delegator, uint96 amount) internal virtual override {
        if (_isDepositedIntoUniStaker(delegator)) {
            _withdrawFromUniStaker(delegator, amount);
        }
        super._beforeWithdraw(delegator, amount);
    }

    /// @dev Before a delegator is slashed, if they are opted into the UniStaker contract, withdraw their stake from the UniStaker contract
    function _beforeSlash(address delegator, uint96 amount, uint96 newStake, uint96 newPendingWithdrawalAmount)
        internal
        virtual
        override
    {
        if (_isDepositedIntoUniStaker(delegator)) {
            _withdrawFromUniStaker(delegator, amount);
        }
        super._beforeSlash(delegator, amount, newStake, newPendingWithdrawalAmount);
    }

    /// @inheritdoc IUniStakerWrapper
    function depositIntoUniStaker(address governanceDelegatee) external returns (uint256 depositId) {
        if (_isDepositedIntoUniStaker(msg.sender)) revert AlreadyDepositedIntoUniStaker();
        _beforeUniStakerDeposit(msg.sender);
        uint96 amount = _delegatorStake(msg.sender);
        depositId = _depositIntoUniStaker(amount, governanceDelegatee);
    }

    /// @inheritdoc IUniStakerWrapper
    function withdrawFromUniStaker() external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        _beforeUniStakerWithdrawal(msg.sender);
        uint96 amount = _delegatorStake(msg.sender);
        _withdrawFromUniStaker(amount);
    }

    /// @inheritdoc IUniStakerWrapper
    function alterGovernanceDelegatee(address newGovernanceDelegatee) external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        _beforeUniStakerDelegateChange(msg.sender, newGovernanceDelegatee);
        _depositIntoUniStaker(0, newGovernanceDelegatee);
    }

    /// @dev Deposits a delegator's stake into the UniStaker contract and/or updates their governance delegatee. On first deposit, the delegator MUST provide both, the stake and a delegatee and a deposit id is returned. On subsequent deposits, the deposit id is reused and identifies the delegator's entire stake.
    function _depositIntoUniStaker(uint96 amount, address delegatee) internal returns (uint256 depositId) {
        depositId = _depositIds[msg.sender];
        if (amount != 0) {
            STAKE_TOKEN.approve(address(UNISTAKER), amount);
        }
        if (depositId == 0) {
            depositId = IUniStaker.DepositIdentifier.unwrap(UNISTAKER.stake(amount, delegatee));
            // @audit technically depositId 0 is a valid depositId in UniStaker but it will probably be used by the time this contract is deployed
            assert(depositId != 0);
            _depositIds[msg.sender] = depositId;
            emit UniStakerDeposited(msg.sender, depositId, amount);
        } else {
            if (amount != 0) {
                UNISTAKER.stakeMore(IUniStaker.DepositIdentifier.wrap(depositId), amount);
                emit UniStakerDeposited(msg.sender, depositId, amount);
            }
            if (delegatee != address(0)) {
                UNISTAKER.alterDelegatee(IUniStaker.DepositIdentifier.wrap(depositId), delegatee);
                emit GovernanceDelegateeAltered(msg.sender, delegatee);
            }
        }
    }

    /// @dev Withdraws an amount from the sender's stake deposited into the UniStaker contract
    function _withdrawFromUniStaker(uint96 amount) internal {
        _withdrawFromUniStaker(msg.sender, amount);
    }

    /// @dev Withdraws an amount from a delegator's stake deposited into the UniStaker contract. If the entire stake is withdrawn, subsequent deposits will no longer auto-deposit into the UniStaker contract.
    function _withdrawFromUniStaker(address delegator, uint96 amount) internal {
        uint256 depositId = _depositIds[delegator];
        // TODO revert if not deposited and amount is not 0
        if (depositId != 0) {
            UNISTAKER.withdraw(IUniStaker.DepositIdentifier.wrap(depositId), amount);
            emit UniStakerWithdrawn(delegator, depositId, amount);
            if (_stakedBalanceOf(delegator) == 0) _depositIds[delegator] = 0;
        }
    }

    // @audit INVARIANT: _stakedBalanceOf >= _slashableStake when accounting for rounding errors when slashing
    function _stakedBalanceOf(address delegator) internal view returns (uint96) {
        uint256 depositId = _depositIds[delegator];
        if (depositId == 0) return 0;
        return UNISTAKER.deposits(IUniStaker.DepositIdentifier.wrap(depositId)).balance;
    }

    function _totalAmountDepositedIntoUniStaker() internal view returns (uint96) {
        // @audit no need for safe cast as UNI supply is < 2^96
        return uint96(UNISTAKER.depositorTotalStaked(address(this)));
    }

    function _isDepositedIntoUniStaker(address delegator) internal view returns (bool) {
        return _depositIds[delegator] != 0;
    }

    function _beforeUniStakerDeposit(address delegator) internal virtual {}

    function _beforeUniStakerWithdrawal(address delegator) internal virtual {}

    function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal virtual {}
}
