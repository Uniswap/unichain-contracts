# RewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/59d8d0f3dfaec834d237a9218ae7c1d8d99315b3/src/UVN/L2/RewardDistributor.sol)

**Inherits:**
[RewardDistributorParams](/src/UVN/L2/RewardDistributorParams.sol/contract.RewardDistributorParams.md), [IRewardDistributor](/src/interfaces/UVN/L2/IRewardDistributor.sol/interface.IRewardDistributor.md)


## State Variables
### L2_STAKE_MANAGER

```solidity
IStakeTable private immutable L2_STAKE_MANAGER;
```


### _windowFinalizationPointer

```solidity
uint256 private _windowFinalizationPointer;
```


### _windowBlockNumbers

```solidity
uint256[] private _windowBlockNumbers;
```


### _windows

```solidity
mapping(uint256 blockNumber => Window window) private _windows;
```


### _attestations

```solidity
mapping(address operator => Attestations attestations) private _attestations;
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
function attest(uint256 blockNumber, bytes32 blockHash, bytes memory additionalData, bytes memory signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number of the last block in the window|
|`blockHash`|`bytes32`|The block hash of the last block in the window|
|`additionalData`|`bytes`|Additional data to include in the attestation, e.g., information whether priority ordering was maintained in the block or the root of the next stake table|
|`signature`|`bytes`|The signature of the operator|


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


### _scheduleNextWindow

*The first attestation to the current window will schedule the next window. Windows are scheduled every `attestationWindowLength` blocks. If there are no attestations during the current window, the next window is not scheduled. In this case the current window will be extended until the next attestation occurs. After this, the next window will be scheduled automatically in the same interval again.*


```solidity
function _scheduleNextWindow() private;
```

### _processRewards


```solidity
function _processRewards(address operator) private;
```

### _finalizeWindow


```solidity
function _finalizeWindow(uint256 window) private;
```

### _currentWindow


```solidity
function _currentWindow() private view returns (Window storage window);
```

### _status


```solidity
function _status(uint256 targetBlockNumber, uint256 windowIndex) private view returns (Status);
```

### _encodeNextWindow


```solidity
function _encodeNextWindow(uint256 blockNumber, uint256 reward) private pure returns (uint256);
```

### _decodeNextWindow


```solidity
function _decodeNextWindow(uint256 nextWindow) private pure returns (uint256 blockNumber, uint256 reward);
```

### _acceptingAttestations


```solidity
function _acceptingAttestations(uint256 blockNumber) private view returns (bool);
```

### _windowDelayed


```solidity
function _windowDelayed(uint256 windowEnd, uint256 windowLength) private view returns (bool);
```

### _findWindowIndex

*perform an exponential search first to find a range that contains the block number and reduces the search space for recent block numbers*


```solidity
function _findWindowIndex(uint256 blockNumber) private view returns (uint256);
```

## Structs
### Window

```solidity
struct Window {
    bool finalized;
    uint256 reward;
    uint256 totalSupply;
    bytes32 blockHash;
    bytes32 mostVotedBlockHash;
    bytes32 mostVotedHash;
    uint256 mostVotedHashVotes;
    uint256 nextWindow;
    uint256 index;
    mapping(bytes32 hash => uint256 votes) attestations;
}
```

### Attestation

```solidity
struct Attestation {
    bytes32 votedHash;
    uint256 votes;
    uint256 next;
}
```

### Attestations

```solidity
struct Attestations {
    uint256 head;
    uint256 tail;
    mapping(uint256 blockNumber => Attestation) attestations;
}
```

