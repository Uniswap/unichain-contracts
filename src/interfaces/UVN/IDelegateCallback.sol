// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDelegateCallback {
    function notifyDelegate(address _staker, uint256 _balance) external;
    function notifyUndelegate(address _staker, uint256 _balance) external;
}
