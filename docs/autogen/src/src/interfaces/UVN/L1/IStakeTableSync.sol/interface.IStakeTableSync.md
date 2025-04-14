# IStakeTableSync
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/interfaces/UVN/L1/IStakeTableSync.sol)

**Inherits:**
[IService](/src/interfaces/UVN/L1/IService.sol/interface.IService.md)

This contract is used to sync the stake table of the StakingMiddleware contract to the L2. On notifications about slashing and balance changes from the StakingMiddleware, the data is forwarded to the StakeTable contract on L2. On deposits of operator ERC-721 tokens, the initial balance of the operator is reported to the StakeTable contract on L2. Should an operator already have delegators before depositing their operator token or should they withdraw their operator token and re-deposit it, inconsistencies in the stake of individual delegators could occur. This contract exposes two sync functions to forcefully sync the correct balances to L2.


## Functions
### sync

Syncs the current stake of a delegator and their operator to L2

*This function can be called to sync inconsistencies in the stake table*

*Callable by anyone*


```solidity
function sync(address delegator) external;
```

### syncOperator

Syncs the current total delegated stake of an operator to L2

*This function can be called to sync inconsistencies in the stake table*

*Callable by anyone*


```solidity
function syncOperator(address operator) external;
```

## Errors
### NotStakingMiddleware
Thrown when the `IService` functions are called by an account other than the StakingMiddleware


```solidity
error NotStakingMiddleware();
```

### NotDelegated
Thrown when the `sync` function is called by an account that is not delegated to an operator


```solidity
error NotDelegated();
```

