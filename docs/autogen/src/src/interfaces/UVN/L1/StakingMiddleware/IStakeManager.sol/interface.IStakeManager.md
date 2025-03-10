# IStakeManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol)

**Inherits:**
[IStakingMiddlewareParams](/src/interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol/interface.IStakingMiddlewareParams.md)


## Functions
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

### STAKE_TOKEN

Returns the stake token


```solidity
function STAKE_TOKEN() external view returns (IERC20);
```

## Events
### StakeDeposited
Emitted when a delegator deposits a stake in the StakingMiddleware contract


```solidity
event StakeDeposited(address indexed delegator, uint96 amount);
```

### StakeWithdrawn
Emitted when a delegator withdraws a stake from the StakingMiddleware contract


```solidity
event StakeWithdrawn(address indexed delegator, uint96 amount);
```

### StakeSlashed
Emitted when a delegator's stake is slashed


```solidity
event StakeSlashed(address indexed delegator, uint96 amount);
```

## Errors
### InsufficientBalance
Thrown when a user attempts to withdraw more stake than they have deposited


```solidity
error InsufficientBalance();
```

