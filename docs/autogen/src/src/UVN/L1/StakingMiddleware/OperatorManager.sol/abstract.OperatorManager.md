# OperatorManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/6b285bfe59012065422d5d75fc08ddb0d2404ce9/src/UVN/L1/StakingMiddleware/OperatorManager.sol)

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
function selectOperator(address operator) external;
```

### deselectOperator


```solidity
function deselectOperator() external;
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

