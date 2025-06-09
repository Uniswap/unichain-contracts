# RewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/UVN/L2/RewardDistributor.sol)

**Inherits:**
[RewardDistributorParams](/src/UVN/L2/RewardDistributorParams.sol/contract.RewardDistributorParams.md), [IRewardDistributor](/src/interfaces/UVN/L2/IRewardDistributor.sol/interface.IRewardDistributor.md)

Distributes rewards to operators based on their attestations. Operators attest to a group of blocks (windows). Whenever a window is finalized, the reward is distributed to the operators that voted together with the majority of the votes.

*To guarantee the correct allocation of rewards to windows, should no attestations be made to a window, the scheduled window is extended to the previous block before it activates.*

**Note:**
security-contact: security@uniswap.org


## State Variables
### SUCCESSFUL_ATTESTATION_PERCENTAGE
*2/3rd of the total supply need to attest to a block for it to be finalized*


```solidity
uint256 private constant SUCCESSFUL_ATTESTATION_PERCENTAGE = 666_666_666_666_666_667;
```


### PERCENTAGE_DENOMINATOR

```solidity
uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
```


### L2_STAKE_MANAGER

```solidity
IStakeTable private immutable L2_STAKE_MANAGER;
```


### _attestations

```solidity
mapping(address operator => Attestations attestations) private _attestations;
```


### _lastRewardPayout

```solidity
uint256 private _lastRewardPayout;
```


## Functions
### constructor


```solidity
constructor(
    address admin,
    IStakeTable l2StakeManager,
    IRewardPuller rewardPuller_,
    uint256 attestationWindowLength_,
    uint256 attestationPeriod_
) RewardDistributorParams(admin, attestationWindowLength_, attestationPeriod_, rewardPuller_);
```

### receive

*contract can receive rewards by either pulling from the rewardPuller or by being sent ETH directly to this contract*


```solidity
receive() external payable;
```

### attest

Attest to a window of blocks

*The window is always identified by the block number of the last block in the window*


```solidity
function attest(
    uint256 blockNumber,
    bytes32 blockHash,
    bytes calldata additionalData,
    bytes calldata signature,
    bytes32 graffiti
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number of the last block in the window|
|`blockHash`|`bytes32`|The block hash of the last block in the window|
|`additionalData`|`bytes`|Additional data to include in the attestation, e.g., information whether priority ordering was maintained in the block or the root of the next stake table|
|`signature`|`bytes`|The signature of the operator|
|`graffiti`|`bytes32`|The graffiti allows operators to include information about their node in the attestation (e.g., version number)|


### status

Get the status of the window that contains the given block number


```solidity
function status(uint256 targetBlockNumber) public view returns (Status);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`targetBlockNumber`|`uint256`|The block number to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Status`|The status of the window containing the block number|


### attestationResult

Get the result of the attestation for the given block number


```solidity
function attestationResult(uint256 targetBlockNumber) external view returns (AttestationResult);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`targetBlockNumber`|`uint256`|The block number to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`AttestationResult`|The result of the attestation|


### latestActiveWindow

Get the latest active window that can be attested to


```solidity
function latestActiveWindow() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|blockNumber The block number of the last block in the latest active window|


### _activateScheduledWindow

*The first attestation after the scheduled window has passed will activate the scheduled window. If there are no attestations to this window after `attestationLength` blocks, the window will start extending until this function is called on the first attestation or reward distribution.*


```solidity
function _activateScheduledWindow() private;
```

### _processRewards


```solidity
function _processRewards(address operator) private;
```

### _finalizeWindow


```solidity
function _finalizeWindow(uint256 blockNumber) private;
```

### _status


```solidity
function _status(uint256 targetBlockNumber, uint256 windowBlockNumber, bool exists) private view returns (Status);
```

### _acceptingAttestations


```solidity
function _acceptingAttestations(uint256 blockNumber) private view returns (bool);
```

### _activeWindowEndAfterDelay

*When a window is delayed, the active window is extended in increments of `attestationWindowLength` blocks. This function returns the last block of the active window after a delay.*


```solidity
function _activeWindowEndAfterDelay(uint256 nextWindowEnd) private view returns (uint256);
```

