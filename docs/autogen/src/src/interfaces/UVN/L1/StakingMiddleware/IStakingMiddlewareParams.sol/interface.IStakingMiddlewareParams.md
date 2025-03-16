# IStakingMiddlewareParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3cf601aa04842b039a5cf3b59e8450ff86ee0a21/src/interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol)

**Inherits:**
IAccessControl

This contract manages the parameters of the StakingMiddleware contract. It allows roles to set the withdrawal delay and the slashing beneficiary.


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


### updateSlashingBeneficiary

Updates the slashing beneficiary that receives slashed stake and rewards


```solidity
function updateSlashingBeneficiary(address slashingBeneficiary) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`slashingBeneficiary`|`address`|The new slashing beneficiary|


### withdrawalDelay

The delay before a user can withdraw their stake or change their operator


```solidity
function withdrawalDelay() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The withdrawal delay in seconds|


### slashingBeneficiary

The slashing beneficiary that receives slashed stake and rewards


```solidity
function slashingBeneficiary() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The slashing beneficiary|


### PARAMS_SETTER_ROLE

The role that can set parameters


```solidity
function PARAMS_SETTER_ROLE() external view returns (bytes32);
```

## Events
### WithdrawalDelayUpdated
Emitted when the withdrawal delay is updated


```solidity
event WithdrawalDelayUpdated(uint256 oldWithdrawalDelay, uint256 newWithdrawalDelay);
```

### SlashingBeneficiaryUpdated
Emitted when the slashing beneficiary is updated


```solidity
event SlashingBeneficiaryUpdated(address oldSlashingBeneficiary, address newSlashingBeneficiary);
```

