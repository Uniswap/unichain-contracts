// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDelegationManagerHook {
    function beforeDelegate(address _staker, uint256 _balance) external;
    function afterDelegate(address _staker, uint256 _balance) external;

    function beforeUndelegate(address _staker, uint256 _balance) external;
    function afterUndelegate(address _staker, uint256 _balance) external;
}
