# StakingMiddlewareParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol)

**Inherits:**
[IStakingMiddlewareParams](/src/interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol/interface.IStakingMiddlewareParams.md), AccessControl

This contract manages the parameters of the StakingMiddleware contract. It allows roles to set the withdrawal delay and the slashing beneficiary.


## State Variables
### PARAMS_SETTER_ROLE

```solidity
bytes32 public constant PARAMS_SETTER_ROLE = keccak256('PARAMS_SETTER_ROLE');
```


### _withdrawalDelay

```solidity
uint256 private _withdrawalDelay;
```


### _slashingBeneficiary

```solidity
address private _slashingBeneficiary;
```


## Functions
### constructor


```solidity
constructor(address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_);
```

### withdrawalDelay

The delay before a user can withdraw their stake or change their operator


```solidity
function withdrawalDelay() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The withdrawal delay in seconds|


### slashingBeneficiary

The slashing beneficiary that receives slashed stake and rewards


```solidity
function slashingBeneficiary() public view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The slashing beneficiary|


### updateWithdrawalDelay

Updates the withdrawal delay


```solidity
function updateWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(PARAMS_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalDelay_`|`uint256`||


### updateSlashingBeneficiary

Updates the slashing beneficiary that receives slashed stake and rewards


```solidity
function updateSlashingBeneficiary(address slashingBeneficiary_) external onlyRole(PARAMS_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`slashingBeneficiary_`|`address`||


### _setWithdrawalDelay


```solidity
function _setWithdrawalDelay(uint256 withdrawalDelay_) internal;
```

### _setSlashingBeneficiary


```solidity
function _setSlashingBeneficiary(address slashingBeneficiary_) internal;
```

