# OperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/UVN/L1/StakingMiddleware/OperatorManager.sol)

**Inherits:**
[Votes](/src/UVN/L1/StakingMiddleware/libraries/Votes.sol/abstract.Votes.md), [ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [IOperatorManager](/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol/interface.IOperatorManager.md)


## Functions
### constructor


```solidity
constructor() EIP712('UVN-StakingMiddleware', '1');
```

### _afterDeposit


```solidity
function _afterDeposit(address delegator, uint96 amount) internal virtual override;
```

### _afterWithdrawal


```solidity
function _afterWithdrawal(address delegator, uint96 amount) internal virtual override;
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

### _beforeOperatorDeselection


```solidity
function _beforeOperatorDeselection(address delegator) internal virtual;
```

### _afterOperatorDeselection


```solidity
function _afterOperatorDeselection(address delegator) internal virtual;
```

