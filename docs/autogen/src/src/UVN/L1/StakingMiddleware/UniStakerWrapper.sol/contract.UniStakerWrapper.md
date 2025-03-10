# UniStakerWrapper
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol)

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


```solidity
function depositIntoUniStaker(address governanceDelegatee) external returns (uint256 depositId);
```

### withdrawFromUniStaker


```solidity
function withdrawFromUniStaker() external;
```

### alterGovernanceDelegatee


```solidity
function alterGovernanceDelegatee(address newGovernanceDelegatee) external;
```

### updateGovernanceDelegatee


```solidity
function updateGovernanceDelegatee(address newGovernanceDelegatee) external;
```

### _afterDeposit


```solidity
function _afterDeposit(address delegator, uint96 amount) internal virtual override;
```

### _beforeWithdrawal


```solidity
function _beforeWithdrawal(address delegator, uint96 amount) internal virtual override;
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

### _totalAmountStaked


```solidity
function _totalAmountStaked() internal view returns (uint96);
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

