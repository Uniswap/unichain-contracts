# Windows
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/b7383382c1ce8df5f5120f02338dfd44fd340bf2/src/UVN/L2/libraries/WindowLib.sol)


```solidity
struct Windows {
    uint256[] blockNumbers;
    uint256 windowLength;
    mapping(uint256 blockNumber => Window window) windows;
}
```

