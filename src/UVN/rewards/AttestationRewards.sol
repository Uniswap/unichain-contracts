// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {ICrossDomainMessenger} from "../../interfaces/IL2CrossDomainMessenger.sol";
import {IStakeManager} from "../../interfaces/UVN/IStakeManager.sol";
import {OperatorData} from "../base/BaseStructs.sol";

/// @title AttestationRewards
/// @notice This contract distributes rewards in ETH for stakers that attest to blocks.
///         The contract is inspired on `StakingRewards.sol` from Uniswap:
///         https://github.com/Uniswap/liquidity-staker/blob/3edce550aeeb7b0c17a10701ff4484d6967e345f/contracts/StakingRewards.sol
contract AttestationRewards {
    using FixedPointMathLib for uint256;

    /// @notice Emitted when rewards are distributed to a vault.
    event RewardsDistributed(address indexed vault, uint256 reward);

    /// @notice Thrown when the caller is not CrossDomainMessenger and origin contract is not CrossDomainStaker.
    error OnlyCrossDomainStaker();

    /// @notice Thrown when the block number is not an epoch start.
    error NotEpochStart();

    /// @notice Thrown when the epoch is not the current epoch.
    error NotCurrentEpoch();

    /// @notice Thrown when the block epoch is already attested.
    error AlreadyAttestedEpoch();

    /// @notice Thrown when the block hash is invalid
    error InvalidBlockHash();

    /// @notice Thrown when rewards payment fails.
    error TransferFailed();

    /// @notice Thrown when the attester is not registered for a vault.
    error InvalidVault();

    /// @notice Thrown when the vault has insufficient balance.
    error InsufficientBalance();

    /// @notice EpochData struct.
    /// @dev    Fits in a single storage slot.
    /// @param rewardPerToken The reward per token value.
    /// @param lastAttestedEpochNumber The last epoch number for which the rewards were distributed.
    struct EpochData {
        uint160 rewardPerToken;
        uint32 lastAttestedEpochNumber;
    }

    mapping(address attester => uint32 lastAttestedEpochNumber) public lastAttestedEpochNumber;

    /// @notice The domain typehash for the EIP712 signature.
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The typehash for the Attest struct.
    bytes32 public constant ATTEST_TYPEHASH =
        keccak256("Attest(address attester,uint128 blockNumber,bytes32 blockHash)");

    /// @notice The length of an epoch.
    uint32 public constant EPOCH_LENGTH = 10;

    /// @notice The minimum balance in bps (relative to totalStake) for an attester to be eligible for rewards.
    uint256 public constant MIN_BALANCE_BPS = 100; // 1%
    uint256 public constant BPS = 10_000;

    /// @notice The FeeDisburser contract.
    FeeDisburser public immutable FEE_DISBURSER;

    /// @notice The StakeManager contract.
    IStakeManager public immutable STAKE_MANAGER;

    /// @notice The current epoch data.
    EpochData public epochData;

    /// @param _feeDisburser The address of the FeeDisburser contract.
    /// @param _stakeManager The address of the StakeManager contract.
    constructor(address payable _feeDisburser, address _stakeManager) {
        FEE_DISBURSER = FeeDisburser(_feeDisburser);
        STAKE_MANAGER = IStakeManager(_stakeManager);
    }

    /// @notice Payable fallback function
    receive() external payable {}

    /// @notice Attest to a block with `_blockHash` at block number `_blockNumber`.
    /// @param _blockNumber The block number of the block to attest to.
    /// @param _blockHash The block hash of the block to attest to.
    function attest(uint32 _blockNumber, bytes32 _blockHash) external returns (uint256 _balance, uint256 _reward) {
        (_balance, _reward) = _attest(msg.sender, _blockNumber, _blockHash, msg.sender);
    }

    /// @notice Attest to a block with `_blockHash` at block number `_blockNumber` as `_attester` to a different vault.
    /// @param _blockNumber The block number of the block to attest to.
    /// @param _blockHash The block hash of the block to attest to.
    /// @param _vault The address of the vault to receive the rewards.
    function attest(uint32 _blockNumber, bytes32 _blockHash, address _vault)
        external
        returns (uint256 _balance, uint256 _reward)
    {
        (_balance, _reward) = _attest(msg.sender, _blockNumber, _blockHash, _vault);
    }

    /// @notice Attest to a block with `_blockHash` at block number `_blockNumber` as `_attester` with a signature.
    /// @param _blockNumber The block number of the block to attest to.
    /// @param _blockHash The block hash of the block to attest to.
    /// @param _v The v value of the signature.
    /// @param _r The r value of the signature.
    /// @param _s The s value of the signature.
    function attestWithSignature(uint32 _blockNumber, bytes32 _blockHash, uint8 _v, bytes32 _r, bytes32 _s)
        public
        returns (uint256 _balance, uint256 _reward)
    {
        address attester = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    keccak256(
                        abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("StakingRewards")), block.chainid, address(this))
                    ),
                    keccak256(abi.encode(ATTEST_TYPEHASH, _blockNumber, _blockHash))
                )
            ),
            _v,
            _r,
            _s
        );

        // TODO: support specifying vault here
        (_balance, _reward) = _attest(attester, _blockNumber, _blockHash, attester);
    }

    /// @notice Attest to a block with `_blockHash` at block number `_blockNumber` as `_attester` with multiple signatures.
    /// @param _blockNumber The block number of the block to attest to.
    /// @param _blockHash The block hash of the block to attest to.
    /// @param _v The v values of the signatures.
    /// @param _r The r values of the signatures.
    /// @param _s The s values of the signatures.
    function attestWithSignatures(
        uint32 _blockNumber,
        bytes32 _blockHash,
        uint8[] calldata _v,
        bytes32[] calldata _r,
        bytes32[] calldata _s
    ) external returns (uint256[] memory _balance, uint256[] memory _reward) {
        _balance = new uint256[](_v.length);
        _reward = new uint256[](_v.length);

        for (uint256 i = 0; i < _v.length; i++) {
            (_balance[i], _reward[i]) = attestWithSignature(_blockNumber, _blockHash, _v[i], _r[i], _s[i]);
        }
    }

    /// @notice Attest to a block with `_blockHash` at block number `_blockNumber` as `_attester`.
    /// @param _attester The address of the attester.
    /// @param _blockNumber The block number of the block to attest to.
    /// @param _blockHash The block hash of the block to attest to.
    /// @param _vault The address of the vault to receive the rewards.
    /// @return _balance The effective balance at the time of the attestation.
    /// @return _reward The reward amount of the attestation.
    function _attest(address _attester, uint32 _blockNumber, bytes32 _blockHash, address _vault)
        internal
        returns (uint256 _balance, uint256 _reward)
    {
        if (_blockNumber % EPOCH_LENGTH != 0) revert NotEpochStart();

        uint32 currentEpochNumber = _getCurrentEpochNumber();
        uint32 epochNumber = _blockNumber / EPOCH_LENGTH;
        uint256 _totalStake = STAKE_MANAGER.totalSupply();

        // only attest for current epoch
        if (epochNumber != currentEpochNumber) revert NotCurrentEpoch();

        // check if this is the first attestation for the epoch
        if (epochData.lastAttestedEpochNumber != currentEpochNumber) {
            // NOTE: alternatively, the FeeDisburser could send the rewards to the StakingRewards contract
            //       automatically whenever it receveives eth.
            FEE_DISBURSER.disburseFees();
            epochData.rewardPerToken = uint160(address(this).balance.divWad(_totalStake));
            epochData.lastAttestedEpochNumber = currentEpochNumber;
        }

        // ensure the block hash is valid
        if (_blockHash != blockhash(_blockNumber)) revert InvalidBlockHash();

        OperatorData memory _operatorData = STAKE_MANAGER.operatorData(_attester);

        _balance =
            _blockInCurrentEpoch(_operatorData.lastSyncedBlock) ? _operatorData.sharesLast : _operatorData.sharesCurrent;

        // ensure the attester has at least MIN_BALANCE_BPS of the total supply
        if (_balance < _totalStake.fullMulDiv(MIN_BALANCE_BPS, BPS)) revert InsufficientBalance();

        // only give rewards if the attester participated in the previous epoch
        if (lastAttestedEpochNumber[_attester] != currentEpochNumber - 1) {
            _reward = _balance.mulWad(epochData.rewardPerToken);
        }

        lastAttestedEpochNumber[_attester] = currentEpochNumber;

        // Distribute rewards to the attester
        (bool success,) = _vault.call{value: _reward}("");
        if (!success) revert TransferFailed();

        emit RewardsDistributed(_vault, _reward);
    }

    function _blockInCurrentEpoch(uint32 _blockNumber) internal view returns (bool) {
        uint32 currentEpochNumber = _getCurrentEpochNumber();
        return
            _blockNumber >= currentEpochNumber * EPOCH_LENGTH && _blockNumber < (currentEpochNumber + 1) * EPOCH_LENGTH;
    }

    /// @notice Gets the current epoch number.
    /// @return _epochNumber The current epoch number.
    function _getCurrentEpochNumber() internal view returns (uint32 _epochNumber) {
        _epochNumber = uint32(block.number / EPOCH_LENGTH);
    }
}
