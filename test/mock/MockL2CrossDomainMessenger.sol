// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IL2CrossDomainMessenger} from '../../src/interfaces/IL2CrossDomainMessenger.sol';

contract MockL2CrossDomainMessenger is IL2CrossDomainMessenger {
    address sender;

    function setSender(address _sender) external {
        sender = _sender;
    }

    function xDomainMessageSender() external view returns (address) {
        return sender;
    }
}
