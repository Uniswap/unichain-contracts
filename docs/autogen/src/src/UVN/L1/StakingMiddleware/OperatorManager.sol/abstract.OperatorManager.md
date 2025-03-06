# OperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/24150a287633bc355fa0bd43e8e420b312a5ca02/src/UVN/L1/StakingMiddleware/OperatorManager.sol)

**Inherits:**
[StakingMiddlewareParams](/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol/contract.StakingMiddlewareParams.md)


## State Variables
### _depositorData

```solidity
mapping(address delegator => DepositorData data) internal _depositorData;
```


### _operatorTotalStake

```solidity
mapping(address operator => uint256 totalStake) internal _operatorTotalStake;
```


## Functions
### selectOperator


```solidity
function selectOperator(address operator) public virtual;
```

### deselectOperator


```solidity
function deselectOperator() public virtual;
```

### totalOperatorStake


```solidity
function totalOperatorStake(address operator) public view returns (uint256);
```

### delegatorStake


```solidity
function delegatorStake(address delegator) public view virtual returns (uint96);
```

### _operator


```solidity
function _operator(address delegator) internal view returns (address);
```

## Errors
### OperatorAlreadySelected

```solidity
error OperatorAlreadySelected();
```

### NoOperatorSelected

```solidity
error NoOperatorSelected();
```

