# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/5b98eecce12fe90fe24abd37da1a3642b02cfbd3/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [StakingMiddlewareParams](/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol/contract.StakingMiddlewareParams.md), [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)


## State Variables
### _selectedOperators

```solidity
mapping(address delegator => address operator) internal _selectedOperators;
```


### _operatorTotalStake

```solidity
mapping(address operator => uint256 totalStake) internal _operatorTotalStake;
```


## Functions
### constructor


```solidity
constructor(address initialAdmin, IUniStaker unistaker_, uint256 withdrawalDelay_)
    UniStakerWrapper(unistaker_)
    StakingMiddlewareParams(initialAdmin, withdrawalDelay_);
```

### updateGovernanceDelegatee


```solidity
function updateGovernanceDelegatee(address newGovernanceDelegatee) external;
```

### deposit


```solidity
function deposit(uint256 amount, address governanceDelegatee) external;
```

### withdraw


```solidity
function withdraw(uint256 amount) external;
```

### selectOperator


```solidity
function selectOperator(address operator) external;
```

### deselectOperator


```solidity
function deselectOperator() external;
```

