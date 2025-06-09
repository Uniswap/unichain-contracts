# IRewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/interfaces/UVN/L2/IRewardDistributor.sol)

**Inherits:**
[IRewardDistributorParams](/src/interfaces/UVN/L2/IRewardDistributorParams.sol/interface.IRewardDistributorParams.md)

Distributes rewards to operators based on their attestations. Operators attest to a group of blocks (windows). Whenever a window is finalized, the reward is distributed to the operators that voted together with the majority of the votes.

*To guarantee the correct allocation of rewards to windows, should no attestations be made to a window, the scheduled window is extended to the previous block before it activates.*


## Functions
### attest

Attest to a window of blocks

*The window is always identified by the block number of the last block in the window*

*The additional data has to match the data of other operators to be able to reach consensus*


```solidity
function attest(
    uint256 blockNumber,
    bytes32 blockHash,
    bytes memory additionalData,
    bytes memory signature,
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
function latestActiveWindow() external view returns (uint256 blockNumber);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number of the last block in the latest active window|


## Events
### AttestationWindowExtended
Emitted when a window is extended due to a delay


```solidity
event AttestationWindowExtended(uint256 originalWindowEnd, uint256 newWindowEnd);
```

### AttestationWindowActivated
Emitted when a scheduled window is activated and a new pending window is scheduled


```solidity
event AttestationWindowActivated(uint256 activeWindow, uint256 nextScheduledWindow);
```

### Attested
Emitted when an attestation is submitted


```solidity
event Attested(address indexed operator, uint256 indexed blockNumber, bytes32 indexed graffiti, bytes32 votedHash);
```

### RewardReceived
Emitted when rewards are received


```solidity
event RewardReceived(uint256 indexed window, uint256 amount);
```

### WindowFinalized
Emitted when a window is finalized


```solidity
event WindowFinalized(
    uint256 indexed blockNumber, AttestationResult indexed result, uint256 attestationRatio, uint256 rewardsToDistribute
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number of the last block in the window|
|`result`|`AttestationResult`|The result of the attestation|
|`attestationRatio`|`uint256`|The ratio of stake that voted in relation to the total stake|
|`rewardsToDistribute`|`uint256`|The adjusted amount of rewards to distribute according to the attestation ratio|

## Errors
### NoBlockHashAvailable
Thrown when the block is in the future


```solidity
error NoBlockHashAvailable();
```

### AttestationPeriodPassed
Thrown when the attestation period has passed for a window


```solidity
error AttestationPeriodPassed();
```

### WindowAlreadyFinalized
Thrown when the window has already been finalized


```solidity
error WindowAlreadyFinalized();
```

### BlockAlreadyAttested
Thrown when the operator has already attested to the block


```solidity
error BlockAlreadyAttested();
```

### WindowNotFound
Thrown when the block number an operator is attesting to does not identify a window


```solidity
error WindowNotFound();
```

### RewardDistributionFailed
Thrown when the reward distribution to an operator fails


```solidity
error RewardDistributionFailed();
```

### ZeroVotes
Thrown when the operator has 0 votes


```solidity
error ZeroVotes();
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

### AttestationResult
The result of the attestation for the given block number

*Pending: The attestation period has not passed yet and no majority has voted for the block yet*

*InsufficientVotes: The attestation period has passed and no majority has voted for the block yet*

*Valid: a majority has voted for the block and the voted block hash matches the on chain block hash*

*Invalid: The attestation period has passed and a majority has voted for a different block*


```solidity
enum AttestationResult {
    Pending,
    InsufficientVotes,
    Invalid,
    Valid
}
```

