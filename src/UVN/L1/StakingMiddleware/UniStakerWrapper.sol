// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IERC20, IUniStaker, IUniStakerWrapper
} from '../../../interfaces/UVN/L1/StakingMiddleware/IUniStakerWrapper.sol';
import {StakeManager} from './StakeManager.sol';

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

    /// @inheritdoc IUniStakerWrapper
    function depositIntoUniStaker(address governanceDelegatee) external returns (uint256 depositId) {
        if (_isDepositedIntoUniStaker(msg.sender)) revert AlreadyDepositedIntoUniStaker();
        uint96 amount = _delegatorStake(msg.sender);
        _beforeUniStakerDeposit(msg.sender, amount);
        depositId = _depositIntoUniStaker(amount, governanceDelegatee);
    }

    /// @inheritdoc IUniStakerWrapper
    function withdrawFromUniStaker() external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        uint96 amount = _delegatorStake(msg.sender);
        _beforeUniStakerWithdrawal(msg.sender, amount);
        _withdrawFromUniStaker(amount);
    }

    /// @inheritdoc IUniStakerWrapper
    function alterGovernanceDelegatee(address newGovernanceDelegatee) external {
        if (!_isDepositedIntoUniStaker(msg.sender)) revert NotDepositedIntoUniStaker();
        _beforeUniStakerDelegateChange(msg.sender, newGovernanceDelegatee);
        _depositIntoUniStaker(0, newGovernanceDelegatee);
    }

    function _afterStake(address delegator, uint96 amount) internal virtual override {
        if (_isDepositedIntoUniStaker(delegator)) {
            _depositIntoUniStaker(amount, address(0));
        }
        super._afterStake(delegator, amount);
    }

    function _beforeWithdraw(address delegator, uint96 amount) internal virtual override {
        if (_isDepositedIntoUniStaker(delegator)) {
            _withdrawFromUniStaker(delegator, amount);
        }
        super._beforeWithdraw(delegator, amount);
    }

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

    function _depositIntoUniStaker(uint96 amount, address delegatee) internal returns (uint256 depositId) {
        depositId = _depositIds[msg.sender];
        if (amount != 0) {
            // @audit later conversion to uint96 is safe as the supply of the token is < 2^96
            STAKE_TOKEN.approve(address(UNISTAKER), amount);
        }
        if (depositId == 0) {
            depositId = IUniStaker.DepositIdentifier.unwrap(UNISTAKER.stake(amount, delegatee));
            // @audit technically depositId 0 is a valid depositId in Unistaker but it will probably be used by the time this contract is deployed
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

    function _withdrawFromUniStaker(uint96 amount) internal {
        _withdrawFromUniStaker(msg.sender, amount);
    }

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

    function _beforeUniStakerDeposit(address delegator, uint96 amount) internal virtual {}

    function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal virtual {}

    function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal virtual {}
}
