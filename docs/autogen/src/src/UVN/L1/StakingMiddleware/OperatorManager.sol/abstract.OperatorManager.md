# OperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/UVN/L1/StakingMiddleware/OperatorManager.sol)

**Inherits:**
[OperatorVotes](/src/UVN/L1/StakingMiddleware/libraries/OperatorVotes.sol/abstract.OperatorVotes.md), [ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [IOperatorManager](/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol/interface.IOperatorManager.md)

This contract manages the selection of operators by delegators. The selection of operators implements the `IVotes` interface. Before a delegator can undelegate from an operator, they must pass a delay period. During this delay period their voting power is set to 0 but they remain slashable until the undelegation is finalized.


## State Variables
### _slashableStakes

```solidity
mapping(address operator => uint256 amount) private _slashableStakes;
```


### _undelegationData

```solidity
mapping(address delegator => UndelegationData undelegationData) private _undelegationData;
```


## Functions
### constructor


```solidity
constructor(string memory name) EIP712(name, '1');
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

### _slashableOperatorOf

*Returns the current operator of a delegator, if the delegator has an active undelegation, the operator before the undelegation announcement is returned, otherwise the current operator is returned*


```solidity
function _slashableOperatorOf(address delegator) internal view returns (address);
```

### _beforeDelegation


```solidity
function _beforeDelegation(address delegator, address operator) internal virtual;
```

### _afterDelegation


```solidity
function _afterDelegation(address delegator, address operator) internal virtual;
```

### _beforeUndelegationAnnouncement


```solidity
function _beforeUndelegationAnnouncement(address delegator) internal virtual;
```

### _afterUndelegationAnnouncement


```solidity
function _afterUndelegationAnnouncement(address delegator) internal virtual;
```

### _beforeUndelegation


```solidity
function _beforeUndelegation(address delegator) internal virtual;
```

### _afterUndelegation


```solidity
function _afterUndelegation(address delegator) internal virtual;
```

## Structs
### UndelegationData
*Storage for data required to finalize an undelegation*


```solidity
struct UndelegationData {
    address operator;
    uint96 undelegateAt;
}
```

