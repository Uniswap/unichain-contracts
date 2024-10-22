// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IL2CrossDomainMessenger} from "../../interfaces/IL2CrossDomainMessenger.sol";

/// @title StakeManager
contract StakeManager {
    /// @notice Emitted when `staker` balance is updated
    event Synced(address indexed staker, uint256 oldValue, uint256 newValue);

    /// @notice Thrown when the caller is not CrossDomainMessenger and origin contract is not CrossDomainStaker.
    error OnlyCrossDomainStaker();

    /// @notice The L2CrossDomainMessenger contract.
    IL2CrossDomainMessenger public immutable L2_CROSS_DOMAIN_MESSENGER;

    mapping(address staker => uint256 balance) public balanceOf;

    /// @notice The address of the CrossDomainStaker contract in the L1.
    address public immutable CROSS_DOMAIN_STAKER;

    /// @notice The total supply of the staked tokens.
    uint256 public totalSupply;

    constructor(address _l2CrossDomainMessenger, address _crossDomainStaker) {
        L2_CROSS_DOMAIN_MESSENGER = IL2CrossDomainMessenger(_l2CrossDomainMessenger);
        CROSS_DOMAIN_STAKER = _crossDomainStaker;
    }

    /// @notice Sets the balance of the `_staker` to `_value`.
    /// @dev    The caller MUST be the CrossDomainStaker contract in the L1.
    /// @param _staker The address of the staker.
    /// @param _value The value amount to set.
    /// @param _extraData The extra data bytes from the CrossDomainStaker.
    function sync(address _staker, uint256 _value, bytes calldata _extraData) external {
        if (
            msg.sender != address(L2_CROSS_DOMAIN_MESSENGER)
                || L2_CROSS_DOMAIN_MESSENGER.xDomainMessageSender() != CROSS_DOMAIN_STAKER
        ) {
            revert OnlyCrossDomainStaker();
        }

        uint256 balance0 = balanceOf[_staker];

        if (_value > balance0) {
            totalSupply += _value - balance0;
        } else if (_value < balance0) {
            totalSupply -= balance0 - _value;
        }

        balanceOf[_staker] = _value;

        emit Synced({staker: _staker, oldValue: balance0, newValue: _value});
    }
}
