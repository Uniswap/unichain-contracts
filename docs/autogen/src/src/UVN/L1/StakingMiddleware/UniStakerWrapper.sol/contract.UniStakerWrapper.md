# UniStakerWrapper
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/6d1250e6e2f4daafd93fa5827aed4385164029bb/src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol)

**Inherits:**
[StakeManager](/src/UVN/L1/StakingMiddleware/StakeManager.sol/contract.StakeManager.md), [IUniStakerWrapper](/src/interfaces/UVN/L1/StakingMiddleware/IUniStakerWrapper.sol/interface.IUniStakerWrapper.md)


## State Variables
### UNISTAKER
Returns the UniStaker contract


```solidity
IUniStaker public immutable UNISTAKER;
```


### REWARD_TOKEN
Returns the reward token


```solidity
IERC20 public immutable REWARD_TOKEN;
```


### _depositIds

```solidity
mapping(address delegator => uint256 depositId) private _depositIds;
```


## Functions
### constructor


```solidity
constructor(IUniStaker unistaker, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    StakeManager(address(unistaker.STAKE_TOKEN()), initialAdmin, withdrawalDelay_, slashingBeneficiary_);
```

### depositIntoUniStaker

Deposits the user's underlying stake into the UniStaker contract

*Any subsequent deposits will also be deposited into the UniStaker contract*


```solidity
function depositIntoUniStaker(address governanceDelegatee) external returns (uint256 depositId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`governanceDelegatee`|`address`|The address of the governance delegatee to set|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositId`|`uint256`|The depositId of the deposit identifying the deposit in the UniStaker contract|


### withdrawFromUniStaker

Withdraws all of the user's underlying stake from the UniStaker contract


```solidity
function withdrawFromUniStaker() external;
```

### alterGovernanceDelegatee

Alters the governance delegatee of the user's underlying stake in the UniStaker contract


```solidity
function alterGovernanceDelegatee(address newGovernanceDelegatee) external;
```

### _afterStake


```solidity
function _afterStake(address delegator, uint96 amount) internal virtual override;
```

### _beforeWithdraw


```solidity
function _beforeWithdraw(address delegator, uint96 amount) internal virtual override;
```

### _beforeSlash


```solidity
function _beforeSlash(address delegator, uint96 amount, uint96 newStake, uint96 newPendingWithdrawalAmount)
    internal
    virtual
    override;
```

### _depositIntoUniStaker


```solidity
function _depositIntoUniStaker(uint96 amount, address delegatee) internal returns (uint256 depositId);
```

### _withdrawFromUniStaker


```solidity
function _withdrawFromUniStaker(uint96 amount) internal;
```

### _withdrawFromUniStaker


```solidity
function _withdrawFromUniStaker(address delegator, uint96 amount) internal;
```

### _stakedBalanceOf


```solidity
function _stakedBalanceOf(address delegator) internal view returns (uint96);
```

### _totalAmountDepositedIntoUniStaker


```solidity
function _totalAmountDepositedIntoUniStaker() internal view returns (uint96);
```

### _isDepositedIntoUniStaker


```solidity
function _isDepositedIntoUniStaker(address delegator) internal view returns (bool);
```

### _beforeUniStakerDeposit


```solidity
function _beforeUniStakerDeposit(address delegator, uint96 amount) internal virtual;
```

### _beforeUniStakerWithdrawal


```solidity
function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal virtual;
```

### _beforeUniStakerDelegateChange


```solidity
function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal virtual;
```

