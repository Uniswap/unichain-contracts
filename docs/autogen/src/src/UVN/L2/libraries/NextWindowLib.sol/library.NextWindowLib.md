# NextWindowLib
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/UVN/L2/libraries/NextWindowLib.sol)


## Functions
### get

Returns the block number and reward for a given scheduled window


```solidity
function get(NextWindow nextWindow) internal pure returns (uint256 blockNumber_, uint256 reward_);
```

### setBlockNumber

Sets the block number for a new scheduled window


```solidity
function setBlockNumber(uint256 blockNumber_) internal pure returns (NextWindow);
```

### addReward

Adds a reward to the scheduled window


```solidity
function addReward(NextWindow nextWindow, uint256 reward_) internal pure returns (NextWindow);
```

### extendWindow

Extends the scheduled window to the previous block number upon delay


```solidity
function extendWindow(NextWindow nextWindow) internal view returns (NextWindow);
```

### blockNumber

Returns the block number of the scheduled window


```solidity
function blockNumber(NextWindow nextWindow) internal pure returns (uint256 blockNumber_);
```

### reward

Returns the reward of the scheduled window


```solidity
function reward(NextWindow nextWindow) internal pure returns (uint256 reward_);
```

### _encode


```solidity
function _encode(uint256 blockNumber_, uint256 reward_) private pure returns (NextWindow);
```

