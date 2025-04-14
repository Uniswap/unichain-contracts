# IBaseService
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/interfaces/UVN/IBaseService.sol)

This interface is shared between L1 and L2 contracts to receive notifications about slashings, stake changes and operator withdrawals.


## Functions
### reportOperatorStake

This function is called when a delegator's stake changes.


```solidity
function reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|
|`newBalance`|`uint256`|The new balance of the operator.|
|`delegator`|`address`|The address of the delegator.|
|`newDelegatorStake`|`uint256`|The new stake of the delegator.|


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


### onWithdrawal

This function is called when an operator ERC-721 token is transferred away from the service contract.


```solidity
function onWithdrawal(address operator) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|


