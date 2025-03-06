# StakingMiddlewareParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/6b285bfe59012065422d5d75fc08ddb0d2404ce9/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol)

**Inherits:**
[IStakingMiddlewareParams](/src/interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol/interface.IStakingMiddlewareParams.md), AccessControl


## State Variables
### PARAMS_SETTER_ROLE

```solidity
bytes32 public constant PARAMS_SETTER_ROLE = keccak256('PARAMS_SETTER_ROLE');
```


### _withdrawalDelay

```solidity
uint256 private _withdrawalDelay;
```


### _delegationManager

```solidity
IDelegationManager private _delegationManager;
```


## Functions
### constructor


```solidity
constructor(address initialAdmin, uint256 withdrawalDelay_, IDelegationManager delegationManager_);
```

### withdrawalDelay


```solidity
function withdrawalDelay() public view returns (uint256);
```

### delegationManager


```solidity
function delegationManager() public view returns (IDelegationManager);
```

### updateWithdrawalDelay


```solidity
function updateWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(PARAMS_SETTER_ROLE);
```

### updateDelegationManager


```solidity
function updateDelegationManager(IDelegationManager delegationManager_) external onlyRole(PARAMS_SETTER_ROLE);
```

### _setWithdrawalDelay


```solidity
function _setWithdrawalDelay(uint256 withdrawalDelay_) internal;
```

### _updateDelegationManager


```solidity
function _updateDelegationManager(IDelegationManager delegationManager_) internal;
```

