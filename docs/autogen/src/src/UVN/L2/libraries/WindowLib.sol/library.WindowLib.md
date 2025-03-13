# WindowLib
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c8c648dc23e382ba7de8e12001eb6ca537ff671f/src/UVN/L2/libraries/WindowLib.sol)


## Functions
### encode


```solidity
function encode(uint256 blockNumber_, uint256 reward) internal pure returns (NextWindow);
```

### decode


```solidity
function decode(NextWindow nextWindow) internal pure returns (uint256 blockNumber_, uint256 reward);
```

### setNextBlockNumber


```solidity
function setNextBlockNumber(uint256 blockNumber_) internal pure returns (NextWindow);
```

### blockNumber


```solidity
function blockNumber(NextWindow nextWindow) internal pure returns (uint256 blockNumber_);
```

