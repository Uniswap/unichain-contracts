# IOperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol)

**Inherits:**
[IProtocolRewardDistributor](/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol/interface.IProtocolRewardDistributor.md)


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

