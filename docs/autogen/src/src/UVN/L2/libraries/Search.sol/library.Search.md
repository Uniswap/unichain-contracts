# Search
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/UVN/L2/libraries/Search.sol)

This library provides functions to search for a target value in an array sorted in ascending order.


## Functions
### exponentialSearchDesc

*Performs exponential descending search to narrow down the range for finding a target value in a array sorted in ascending order with a bias towards higher values*


```solidity
function exponentialSearchDesc(uint256[] storage array, uint256 target)
    internal
    view
    returns (uint256 left, uint256 right);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`left`|`uint256`|the lower index of the range when target is rounded up to the index (array[left - 1] < target <= array[left])|
|`right`|`uint256`|The right index of the range, returns type(uint256).max if the target is greater than all values in the array|


### binarySearchRoundingUp


```solidity
function binarySearchRoundingUp(uint256[] storage array, uint256 target, uint256 left, uint256 right)
    internal
    view
    returns (uint256 index);
```

### min


```solidity
function min(uint256 a, uint256 b) private pure returns (uint256);
```

### max


```solidity
function max(uint256 a, uint256 b) private pure returns (uint256);
```

