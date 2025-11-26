# OperatorTokenLib
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/UVN/L1/StakingMiddleware/libraries/OperatorTokenLib.sol)

This library provides functions to convert between operator addresses and token ids.


## Functions
### toTokenId

*Converts an operator address to a token id*


```solidity
function toTokenId(address operator) internal pure returns (uint256);
```

### toAddress

*Converts a token id to an operator address*


```solidity
function toAddress(uint256 tokenId) internal pure returns (address);
```

