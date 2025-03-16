# OperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/43cfeb46627ac8e6e7739462906618c85350c785/src/UVN/L1/StakingMiddleware/OperatorManager.sol)

**Inherits:**
[Votes](/src/UVN/L1/StakingMiddleware/libraries/Votes.sol/abstract.Votes.md), [ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [IOperatorManager](/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol/interface.IOperatorManager.md)

This contract manages the selection of operators by delegators. The selection of operators implements the `IVotes` interface. Before a delegator can undelegate from an operator, they must pass a delay period. During this delay period their voting power is set to 0 but they remain slashable until the undelegation is finalized.


## State Variables
### _slashableStakes

```solidity
mapping(address operator => uint256 amount) private _slashableStakes;
```


### _undelegationTimestamp

```solidity
mapping(address delegator => uint256 undelegationTimestamp) private _undelegationTimestamp;
```


## Functions
### constructor


```solidity
constructor() EIP712('UVN-StakingMiddleware', '1');
```

### _afterStake

*After a delegator stakes, increase the operator's voting power immediately and increase the slashable stake*


```solidity
function _afterStake(address delegator, uint96 amount) internal virtual override;
```

### _afterUnstake

*After a delegator unstakes their stake, decrease the operator's voting power immediately*


```solidity
function _afterUnstake(address delegator, uint96 amount) internal virtual override;
```

### _afterWithdraw

*After a delegator withdraws their unstaked stake, decrease the slashable stake of the operator*


```solidity
function _afterWithdraw(address delegator, uint96 amount) internal virtual override;
```

### announceOperatorUndelegation

Announces the intention to undelegate from the current operator

*The user can finalize their undelegation after the undelegation delay has passed by calling `delegate` with `address(0)` as the argument*


```solidity
function announceOperatorUndelegation() external;
```

### slashableOperatorStake

Returns the slashable stake of an operator (the sum of all delegator stakes that are delegated to it and their pending withdrawals)


```solidity
function slashableOperatorStake(address operator) public view returns (uint96);
```

### _delegate

*Manages the delegation/undelegation of a delegator to an operator. If the operator is set to `address(0)`, the delegator is undelegated from their current operator. Otherwise, the delegator is delegated to the new operator.*


```solidity
function _delegate(address delegator, address operator) internal override;
```

### _selectOperator

*Delegates a delegator's stake to an operator, the delegator must not be already delegating to an operator and must have any pending undelegation finalized*


```solidity
function _selectOperator(address delegator, address operator) internal;
```

### _deselectOperator

*Undelegates a delegator from an operator, the delegator must first announce their intention to undelegate by calling `announceOperatorUndelegation`. This function can only be called once the delay has passed.*


```solidity
function _deselectOperator(address delegator) internal;
```

### _slashOperatorVotes


```solidity
function _slashOperatorVotes(address operator, uint256 remainingPercentage) internal virtual;
```

### _getVotingUnits


```solidity
function _getVotingUnits(address delegator) internal view virtual override returns (uint256);
```

### _beforeOperatorSelection


```solidity
function _beforeOperatorSelection(address delegator, address operator) internal virtual;
```

### _afterOperatorSelection


```solidity
function _afterOperatorSelection(address delegator, address operator) internal virtual;
```

### _beforeOperatorUndelegationAnnouncement


```solidity
function _beforeOperatorUndelegationAnnouncement(address delegator) internal virtual;
```

### _afterOperatorUndelegationAnnouncement


```solidity
function _afterOperatorUndelegationAnnouncement(address delegator) internal virtual;
```

### _beforeOperatorDeselection


```solidity
function _beforeOperatorDeselection(address delegator) internal virtual;
```

### _afterOperatorDeselection


```solidity
function _afterOperatorDeselection(address delegator) internal virtual;
```

