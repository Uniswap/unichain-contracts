# StakingMiddlewareParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/5b98eecce12fe90fe24abd37da1a3642b02cfbd3/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol)

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


## Functions
### constructor


```solidity
constructor(address initialAdmin, uint256 withdrawalDelay_);
```

### withdrawalDelay


```solidity
function withdrawalDelay() public view returns (uint256);
```

### updateWithdrawalDelay


```solidity
function updateWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(PARAMS_SETTER_ROLE);
```

### _setWithdrawalDelay


```solidity
function _setWithdrawalDelay(uint256 withdrawalDelay_) internal;
```

