# UniStakerWrapper
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/6b285bfe59012065422d5d75fc08ddb0d2404ce9/src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol)


## State Variables
### unistaker

```solidity
IUniStaker internal immutable unistaker;
```


### stakeToken

```solidity
IERC20 internal immutable stakeToken;
```


### rewardToken

```solidity
IERC20 internal immutable rewardToken;
```


### _depositIds

```solidity
mapping(address delegator => uint256 depositId) private _depositIds;
```


## Functions
### constructor


```solidity
constructor(IUniStaker unistaker_);
```

### _depositIntoUniStaker


```solidity
function _depositIntoUniStaker(uint96 amount, address delegatee) internal returns (uint256 depositId);
```

### _withdrawFromUniStaker


```solidity
function _withdrawFromUniStaker(uint96 amount) internal;
```

### _stakedBalanceOf


```solidity
function _stakedBalanceOf(address delegator) internal view returns (uint96);
```

### _totalAmountStaked


```solidity
function _totalAmountStaked() internal view returns (uint256);
```

### _isDepositedIntoUniStaker


```solidity
function _isDepositedIntoUniStaker(address delegator) internal view returns (bool);
```

