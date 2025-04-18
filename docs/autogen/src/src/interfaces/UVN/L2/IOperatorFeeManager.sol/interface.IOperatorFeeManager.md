# IOperatorFeeManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/31f7d1e84e305ebb14dd3f50a3450497938c6404/src/interfaces/UVN/L2/IOperatorFeeManager.sol)

Contracts implementing this interface can be used to calculate the operator fee for a given reward received by delegators

*Must implement the receive function to receive the operator fee*


## Functions
### operatorFee

Calculates the operator fee for a given reward


```solidity
function operatorFee(uint256 reward) external view returns (uint256 fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`uint256`|The reward received by delegators|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint256`|The operator fee taken from the reward|


