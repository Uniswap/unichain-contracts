# WindowLib
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/b7383382c1ce8df5f5120f02338dfd44fd340bf2/src/UVN/L2/libraries/WindowLib.sol)

Library for managing active and scheduled windows


## Functions
### activate

Activates a new scheduled window, automatically schedules the next window


```solidity
function activate(Windows storage $, uint256 blockNumber, uint256 reward, uint256 votingSupply)
    internal
    returns (uint256 nextWindow);
```

### extendScheduledWindow

Should a delay occur, the scheduled window is extended to the previous block number before activation


```solidity
function extendScheduledWindow(Window storage window) internal;
```

### attest

Records an attestation and their votes for a given block hash


```solidity
function attest(Windows storage $, uint256 blockNumber, bytes32 blockHash, bytes32 votedHash, uint256 votes) internal;
```

### recordReward

Records a reward for the scheduled window


```solidity
function recordReward(Windows storage $, uint256 reward) internal returns (uint256 blockNumber);
```

### setWindowLength

Sets the length of the attestation window


```solidity
function setWindowLength(Windows storage $, uint256 windowLength) internal;
```

### currentBlockNumber

Returns the block number of the current window


```solidity
function currentBlockNumber(Windows storage $) internal view returns (uint256);
```

### current

Returns the current window


```solidity
function current(Windows storage $) internal view returns (Window storage window);
```

### find

Finds the window for a given block number


```solidity
function find(Windows storage $, uint256 blockNumber) internal view returns (uint256 window, bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`window`|`uint256`|The block number of the window that contains the block number|
|`<none>`|`bool`|exists Whether the window exists|


### isNextWindowDelayed

Checks if the scheduled window is delayed


```solidity
function isNextWindowDelayed(Windows storage $) internal view returns (bool);
```

### currentWindowLength

Returns the current attestation window length


```solidity
function currentWindowLength(Windows storage $) internal view returns (uint256);
```

### blockNumberOf

Returns the block number of a given window


```solidity
function blockNumberOf(Windows storage $, Window storage window) internal view returns (uint256);
```

### isFinalized

Checks if a window is finalized


```solidity
function isFinalized(Window storage window) internal view returns (bool);
```

### exists

Checks if a window exists


```solidity
function exists(Window storage window) internal view returns (bool);
```

### _findWindowIndex

*performs an exponential search first to find a range that contains the block number and reduces the search space for recent block numbers*


```solidity
function _findWindowIndex(Windows storage $, uint256 blockNumber) private view returns (uint256);
```

### _isWindowDelayed


```solidity
function _isWindowDelayed(uint256 windowEnd, uint256 windowLength) private view returns (bool);
```

