# IDelegatorVerifier
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/07d4bd0c93642e180d59fb2de755cf59c8c044e6/src/interfaces/UVN/L1/StakingMiddleware/IDelegatorVerifier.sol)

Interface for a contract that verifies whether a delegator is allowed to delegate to an operator

*A contract implementing this interface can be deployed by the operator to verify whether a delegator is allowed to delegate to it*


## Functions
### allowDelegation

Returns whether a delegator is allowed to delegate to an operator


```solidity
function allowDelegation(address delegator) external view returns (bool allowDelegation);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|The address of the delegator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`allowDelegation`|`bool`|Whether the delegator is allowed to delegate to an operator|


