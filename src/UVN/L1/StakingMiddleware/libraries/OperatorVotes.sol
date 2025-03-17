// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Votes} from './Votes.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {Checkpoints} from '@openzeppelin/contracts/utils/structs/Checkpoints.sol';

/// @notice This contract extends the Votes contract to be able to slash the operator votes directly, affecting the delegated votes of multiple delegators simultaneously.
abstract contract OperatorVotes is Votes {
    using Checkpoints for Checkpoints.Trace208;

    /// @dev when a delegator delegates to an operator the total supply of votes increases by the total stake of the delegator and vice versa for undelegating
    function _delegate(address account, address delegatee) internal virtual override {
        address oldDelegate = delegates(account);
        _delegatee[account] = delegatee;
        if (oldDelegate == address(0)) {
            _push(_totalCheckpoints, _add, SafeCast.toUint208(_getVotingUnits(account)));
        }
        if (delegatee == address(0)) {
            _push(_totalCheckpoints, _subtract, SafeCast.toUint208(_getVotingUnits(account)));
        }
        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /// @dev Slashes the operator votes (delegated votes of multiple delegators simultaneously), accepts the new amount of votes after slashing
    function _updateOperatorVotesAfterSlashing(address operator, uint96 newVotes) internal virtual {
        uint256 oldVotes = _delegateCheckpoints[operator].latest();
        uint256 diff = oldVotes - newVotes;
        _push(_totalCheckpoints, _subtract, SafeCast.toUint208(diff));
        _moveDelegateVotes(operator, address(0), diff);
    }
}
