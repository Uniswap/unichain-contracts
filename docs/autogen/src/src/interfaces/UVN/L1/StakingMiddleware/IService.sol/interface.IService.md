# IService
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/7dcfc053062e80b4db9d2b818e627cd6f4a79851/src/interfaces/UVN/L1/StakingMiddleware/IService.sol)

**Inherits:**
IERC165

This interface is used by contracts that operators deposit their ERC-721 tokens into to operate for. It must implement the following functions in order to be notified of changes to operator's and delegator's stake.


## Functions
### reportOperatorStake

This function is called when a delegator's stake changes.


```solidity
function reportOperatorStake(address operator, uint96 newBalance, address delegator, uint96 newDelegatorStake)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|
|`newBalance`|`uint96`|The new balance of the operator.|
|`delegator`|`address`|The address of the delegator.|
|`newDelegatorStake`|`uint96`|The new stake of the delegator.|


### reportOperatorSlash

This function is called when an operator is slashed.


```solidity
function reportOperatorSlash(address operator, uint256 remainingPercentage) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|
|`remainingPercentage`|`uint256`|The remaining percentage of the operator's stake.|


### onForceWithdrawal

This function is called when an operator ERC-721 token is forcefully withdrawn.


```solidity
function onForceWithdrawal(address operator) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|


