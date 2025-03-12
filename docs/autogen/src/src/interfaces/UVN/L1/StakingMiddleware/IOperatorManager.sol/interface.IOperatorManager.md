# IOperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/6d1250e6e2f4daafd93fa5827aed4385164029bb/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol)

**Inherits:**
[IProtocolRewardDistributor](/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol/interface.IProtocolRewardDistributor.md)


## Functions
### slashableOperatorStake

Returns the slashable stake of an operator (the sum of all delegator stakes that are delegated to it and their pending withdrawals)


```solidity
function slashableOperatorStake(address operator) external view returns (uint96);
```

## Errors
### OperatorAlreadySelected
Thrown when a delegator attempts to delegate to another operator while already delegating to one


```solidity
error OperatorAlreadySelected();
```

### NoOperatorSelected
Thrown when a delegator attempts to undelegate from an operator while not delegating to one


```solidity
error NoOperatorSelected();
```

