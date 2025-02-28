# IRewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/f7ee30d3904bcf7f9e6eea33683d2c2c6ac756df/src/interfaces/UVN/L2/IRewardDistributor.sol)

**Inherits:**
[IRewardDistributorParams](/src/interfaces/UVN/L2/IRewardDistributorParams.sol/interface.IRewardDistributorParams.md)


## Functions
### attest

Attest to a window of blocks

*The window is always identified by the block number of the last block in the window*

*The additional data has to match the data of other operators to be able to reach consensus*


```solidity
function attest(uint256 blockNumber, bytes32 blockHash, bytes memory additionalData, bytes memory signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number of the last block in the window|
|`blockHash`|`bytes32`|The block hash of the last block in the window|
|`additionalData`|`bytes`|Additional data to include in the attestation|
|`signature`|`bytes`|The signature of the operator|


### status

Get the status of the window that contains the given block number


```solidity
function status(uint256 targetBlockNumber) external view returns (Status);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`targetBlockNumber`|`uint256`|The block number to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Status`|The status of the window containing the block number|


### latestActiveWindow

Get the latest active window that can be attested to


```solidity
function latestActiveWindow() external view returns (uint256 blockNumber);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number of the last block in the latest active window|


## Events
### AttestationWindowScheduled
Emitted when a window is scheduled


```solidity
event AttestationWindowScheduled(uint256 indexed currentWindowEnd, uint256 indexed scheduledNextWindowEnd);
```

### AttestationWindowExtended
Emitted when a window is extended due to a delay


```solidity
event AttestationWindowExtended(uint256 indexed originalWindowEnd, uint256 indexed newWindowEnd);
```

### Attested
Emitted when an attestation is submitted


```solidity
event Attested(address indexed operator, uint256 indexed blockNumber, bytes32 votedHash);
```

### RewardReceived
Emitted when rewards are received


```solidity
event RewardReceived(uint256 indexed window, uint256 amount);
```

## Errors
### BlockAlreadyAttested

```solidity
error BlockAlreadyAttested();
```

### NoBlockHashAvailable

```solidity
error NoBlockHashAvailable();
```

### AttestationPeriodPassed

```solidity
error AttestationPeriodPassed();
```

### InvalidSender

```solidity
error InvalidSender();
```

### WindowNotFound

```solidity
error WindowNotFound();
```

## Enums
### Status
Status of block numbers and windows

*NonExistent: The block number/window is in the future and has not been scheduled*

*Pending: The block number/window is in the future and will become scheduled after the next attestation to the current window*

*Scheduled: The block number/window is in the future and has been scheduled to be attested*

*Delayed: The currently active window has not received any attestations yet and thus the scheduled window is delayed*

*Active: The currently active window that is receiving attestations*

*Finalized: A window has been attested and the attestation period has passed*


```solidity
enum Status {
    NonExistent,
    Pending,
    Scheduled,
    Delayed,
    Active,
    Finalized
}
```

