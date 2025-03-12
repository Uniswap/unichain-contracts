# IOperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/5add0d5c45e74462978e784c9ba783c7840cb2d6/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol)

**Inherits:**
[IProtocolRewardDistributor](/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol/interface.IProtocolRewardDistributor.md)


## Functions
### announceOperatorUndelegation

Announces the intention to undelegate from the current operator

*The user can finalize their undelegation after the undelegation delay has passed by calling `delegate` with `address(0)` as the argument*

*The user remains slashable until the undelegation is finalized*


```solidity
function announceOperatorUndelegation() external;
```

### slashableOperatorStake

Returns the slashable stake of an operator (the sum of all delegator stakes that are delegated to it and their pending withdrawals)


```solidity
function slashableOperatorStake(address operator) external view returns (uint96);
```

## Events
### OperatorUndelegationAnnounced
Emitted when a delegator announces their intention to undelegate from their current operator


```solidity
event OperatorUndelegationAnnounced(address indexed delegator, address indexed operator, uint256 timestamp);
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

### UndelegationNotFinalized
Thrown when a delegator attempts to undelegate from an operator while the undelegation is not finalized


```solidity
error UndelegationNotFinalized(uint256 timestamp);
```

