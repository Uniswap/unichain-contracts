# IStakingMiddlewareParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/5b98eecce12fe90fe24abd37da1a3642b02cfbd3/src/interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol)


## Functions
### updateWithdrawalDelay

Updates the withdrawal delay


```solidity
function updateWithdrawalDelay(uint256 withdrawalDelay) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalDelay`|`uint256`|The new withdrawal delay in seconds|


### withdrawalDelay

The delay before a user can withdraw their stake or change their operator


```solidity
function withdrawalDelay() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The withdrawal delay in seconds|


### PARAMS_SETTER_ROLE

The role that can set parameters


```solidity
function PARAMS_SETTER_ROLE() external view returns (bytes32);
```

## Events
### WithdrawalDelayUpdated

```solidity
event WithdrawalDelayUpdated(uint256 oldWithdrawalDelay, uint256 newWithdrawalDelay);
```

