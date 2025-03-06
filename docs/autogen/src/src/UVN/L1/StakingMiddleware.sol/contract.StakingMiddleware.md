# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/24150a287633bc355fa0bd43e8e420b312a5ca02/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [SlashingManager](/src/UVN/L1/StakingMiddleware/SlashingManager.sol/abstract.SlashingManager.md), [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)


## State Variables
### totalStake

```solidity
uint96 public totalStake;
```


## Functions
### constructor


```solidity
constructor(
    address initialAdmin,
    IUniStaker unistaker_,
    uint256 withdrawalDelay_,
    IDelegationManager delegationManager_
) UniStakerWrapper(unistaker_) StakingMiddlewareParams(initialAdmin, withdrawalDelay_, delegationManager_);
```

### updateGovernanceDelegatee


```solidity
function updateGovernanceDelegatee(address newGovernanceDelegatee) external;
```

### deposit


```solidity
function deposit(uint96 amount) external;
```

### withdraw


```solidity
function withdraw(uint96 amount) external;
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

