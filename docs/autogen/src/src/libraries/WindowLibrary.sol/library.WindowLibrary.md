# WindowLibrary
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/2bea5dafc15ba815c8ba14ba9e39556e6fd5e819/src/libraries/WindowLibrary.sol)


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

