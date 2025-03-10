# StakeManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/UVN/L1/StakingMiddleware/StakeManager.sol)

**Inherits:**
[StakingMiddlewareParams](/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol/contract.StakingMiddlewareParams.md), [IStakeManager](/src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol/interface.IStakeManager.md)


## State Variables
### _depositorStake

```solidity
mapping(address delegator => uint96 stake) private _depositorStake;
```


### STAKE_TOKEN

```solidity
IERC20 public immutable STAKE_TOKEN;
```


## Functions
### constructor


```solidity
constructor(address stakeToken, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    StakingMiddlewareParams(initialAdmin, withdrawalDelay_, slashingBeneficiary_);
```

### delegatorStake

Returns the stake of a delegator deposited in the StakingMiddleware contract


```solidity
function delegatorStake(address delegator) external view returns (uint96);
```

### deposit

Deposits a stake in the StakingMiddleware contract


```solidity
function deposit(uint96 amount) external;
```

### withdraw

Withdraws a stake from the StakingMiddleware contract


```solidity
function withdraw(uint96 amount) external;
```

### _slashDelegatorStake


```solidity
function _slashDelegatorStake(address delegator, uint96 amount) internal;
```

### _delegatorStake


```solidity
function _delegatorStake(address delegator) internal view virtual returns (uint96);
```

### _beforeDeposit


```solidity
function _beforeDeposit(address delegator, uint96 amount) internal virtual;
```

### _afterDeposit


```solidity
function _afterDeposit(address delegator, uint96 amount) internal virtual;
```

### _beforeWithdrawal


```solidity
function _beforeWithdrawal(address delegator, uint96 amount) internal virtual;
```

### _afterWithdrawal


```solidity
function _afterWithdrawal(address delegator, uint96 amount) internal virtual;
```

