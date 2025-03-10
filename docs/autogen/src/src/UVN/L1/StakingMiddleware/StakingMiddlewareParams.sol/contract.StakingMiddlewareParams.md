# StakingMiddlewareParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol)

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


### _slashingBeneficiary

```solidity
address private _slashingBeneficiary;
```


## Functions
### constructor


```solidity
constructor(address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_);
```

### withdrawalDelay


```solidity
function withdrawalDelay() public view returns (uint256);
```

### slashingBeneficiary


```solidity
function slashingBeneficiary() public view returns (address);
```

### updateWithdrawalDelay


```solidity
function updateWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(PARAMS_SETTER_ROLE);
```

### updateSlashingBeneficiary


```solidity
function updateSlashingBeneficiary(address slashingBeneficiary_) external onlyRole(PARAMS_SETTER_ROLE);
```

### _setWithdrawalDelay


```solidity
function _setWithdrawalDelay(uint256 withdrawalDelay_) internal;
```

### _setSlashingBeneficiary


```solidity
function _setSlashingBeneficiary(address slashingBeneficiary_) internal;
```

