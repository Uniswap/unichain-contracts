# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c13e98e1c8d2865602c701181fc3bd205955774b/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [StakingMiddlewareParams](/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol/contract.StakingMiddlewareParams.md), [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)


## State Variables
### _depositorData

```solidity
mapping(address delegator => DepositorData data) internal _depositorData;
```


### _operatorTotalStake

```solidity
mapping(address operator => uint256 totalStake) internal _operatorTotalStake;
```


### totalStake

```solidity
uint256 public totalStake;
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
function deposit(uint256 amount) external;
```

### depositIntoUniStaker


```solidity
function depositIntoUniStaker(address governanceDelegatee) external;
```

### withdrawFromUniStaker


```solidity
function withdrawFromUniStaker() external;
```

### alterGovernanceDelegatee


```solidity
function alterGovernanceDelegatee(address newGovernanceDelegatee) external;
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

