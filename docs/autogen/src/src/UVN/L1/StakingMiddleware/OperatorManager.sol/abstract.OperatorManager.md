# OperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/10fd24e97f437a5e7731628f80c2a61f2eb81fe3/src/UVN/L1/StakingMiddleware/OperatorManager.sol)

**Inherits:**
[Votes](/src/UVN/L1/StakingMiddleware/libraries/Votes.sol/abstract.Votes.md), [ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [IOperatorManager](/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol/interface.IOperatorManager.md)


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


```solidity
function _afterStake(address delegator, uint96 amount) internal virtual override;
```

### _afterUnstake


```solidity
function _afterUnstake(address delegator, uint96 amount) internal virtual override;
```

### _afterWithdraw


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


```solidity
function _delegate(address delegator, address operator) internal override;
```

### _selectOperator


```solidity
function _selectOperator(address delegator, address operator) internal;
```

### _deselectOperator


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

