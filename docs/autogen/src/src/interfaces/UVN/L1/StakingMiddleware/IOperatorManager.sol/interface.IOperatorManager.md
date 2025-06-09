# IOperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/f3a7525f5971b3bc886ba551e43cf8afecfdaa02/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol)

**Inherits:**
[IProtocolRewardDistributor](/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol/interface.IProtocolRewardDistributor.md), IVotes

This contract manages the selection of operators by delegators. The selection of operators implements the `IVotes` interface. Before a delegator can undelegate from an operator, they must pass a delay period. During this delay period their voting power is set to 0 but they remain slashable until the undelegation is finalized.


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
### OperatorSlashed
Emitted when an operator is slashed


```solidity
event OperatorSlashed(address indexed operator, uint96 remainingPercentage);
```

### OperatorUndelegationAnnounced
Emitted when a delegator announces their intention to undelegate from their current operator


```solidity
event OperatorUndelegationAnnounced(address indexed delegator, address indexed operator, uint256 timestamp);
```

## Errors
### AlreadyDelegated
Thrown when a delegator attempts to delegate to another operator while already delegating to one or having a pending undelegation


```solidity
error AlreadyDelegated();
```

### NotDelegated
Thrown when a delegator attempts to undelegate from an operator while not delegating to one


```solidity
error NotDelegated();
```

### AnnounceUndelegationFirst
Thrown when a delegator attempts to undelegate from an operator without announcing their intention to undelegate first


```solidity
error AnnounceUndelegationFirst();
```

### UndelegationNotFinalized
Thrown when a delegator attempts to undelegate from an operator while the undelegation is not finalized


```solidity
error UndelegationNotFinalized(uint256 timestamp);
```

