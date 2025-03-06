// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IUniStaker} from '../../../interfaces/UVN/L1/IUnistaker.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract UniStakerWrapper {
    IUniStaker internal immutable unistaker;
    IERC20 internal immutable stakeToken;
    IERC20 internal immutable rewardToken;

    mapping(address delegator => uint256 depositId) private _depositIds;

    constructor(IUniStaker unistaker_) {
        unistaker = unistaker_;
        stakeToken = IERC20(address(unistaker.STAKE_TOKEN()));
        rewardToken = IERC20(address(unistaker.REWARD_TOKEN()));
    }

    function _depositIntoUniStaker(uint96 amount, address delegatee) internal returns (uint256 depositId) {
        depositId = _depositIds[msg.sender];
        if (amount != 0) {
            // @audit later conversion to uint96 is safe as the supply of the token is < 2^96
            stakeToken.approve(address(unistaker), amount);
        }
        if (depositId == 0) {
            depositId = IUniStaker.DepositIdentifier.unwrap(unistaker.stake(amount, delegatee));
            // @audit technically depositId 0 is a valid depositId in Unistaker but it will probably be used by the time this contract is deployed
            assert(depositId != 0);
            _depositIds[msg.sender] = depositId;
        } else {
            if (amount != 0) {
                unistaker.stakeMore(IUniStaker.DepositIdentifier.wrap(depositId), amount);
            }
            if (delegatee != address(0)) {
                unistaker.alterDelegatee(IUniStaker.DepositIdentifier.wrap(depositId), delegatee);
            }
        }
    }

    function _withdrawFromUniStaker(uint96 amount) internal {
        uint256 depositId = _depositIds[msg.sender];
        if (depositId != 0) {
            unistaker.withdraw(IUniStaker.DepositIdentifier.wrap(depositId), amount);
            if (_stakedBalanceOf(msg.sender) == 0) _depositIds[msg.sender] = 0;
        }
    }

    function _stakedBalanceOf(address delegator) internal view returns (uint96) {
        uint256 depositId = _depositIds[delegator];
        if (depositId == 0) return 0;
        return unistaker.deposits(IUniStaker.DepositIdentifier.wrap(depositId)).balance;
    }

    function _totalAmountStaked() internal view returns (uint256) {
        return unistaker.depositorTotalStaked(address(this));
    }

    function _isDepositedIntoUniStaker(address delegator) internal view returns (bool) {
        return _depositIds[delegator] != 0;
    }
}
