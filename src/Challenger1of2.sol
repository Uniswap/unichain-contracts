// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Challenger1of2
 * @dev This contract serves the role of the Challenger.
 * It enforces a simple 1 of 2 design, where neither party can remove the other's
 * permissions to execute a Challenger call.
 */
contract Challenger1of2 {
    using Address for address;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev The address of Optimism's signer (likely a multisig)
     */
    address public immutable OP_SIGNER;

    /**
     * @dev The address of counter party's signer (likely a multisig)
     */
    address public immutable OTHER_SIGNER;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when a Challenger call is made by a signer.
     * @param _caller The signer making the call.
     * @param _target The target address of the call.
     * @param _value The amount of ETH sent.
     * @param _data The data of the call being made.
     * @param _result The result of the call being made.
     */
    event ChallengerCallExecuted(address indexed _caller, address indexed _target, uint256 _value, bytes _data, bytes _result);

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Constructor to set the values of the constants.
     * @param _opSigner Address of Optimism signer.
     * @param _otherSigner Address of counter party signer.
     */
    constructor(address _opSigner, address _otherSigner) {
        require(_opSigner != address(0), "Challenger1of2: opSigner cannot be zero address");
        require(_otherSigner != address(0), "Challenger1of2: otherSigner cannot be zero address");

        OP_SIGNER = _opSigner;
        OTHER_SIGNER = _otherSigner;
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Executes a call as the Challenger (must be called by
     * Optimism or counter party signer).
     * @param _target Address to call.
     * @param _value Amount of ETH to send.
     * @param _data Data for function call.
     */
    function execute(address _target, uint256 _value, bytes memory _data) external payable {
        require(
            msg.sender == OTHER_SIGNER || msg.sender == OP_SIGNER,
            "Challenger1of2: must be an approved signer to execute"
        );
        require(_target.isContract(), "Challenger1of2: target must be a contract");

        bytes memory result = Address.functionCallWithValue(_target, _data, _value, "Challenger1of2: failed to execute");

        emit ChallengerCallExecuted(msg.sender, _target, _value, _data, result);
    }
}

