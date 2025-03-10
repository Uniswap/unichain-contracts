# ISlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol)


## Functions
### slashAmount

Slashes a delegator's stake by a specific amount


```solidity
function slashAmount(address operator, uint96 amount) external;
```

### slashPercentage

Slashes a delegator's stake by a percentage of the total stake


```solidity
function slashPercentage(address operator, uint96 percentage) external;
```

### applySlashing

Applies pending slashing to a delegator's stake


```solidity
function applySlashing(address delegator, uint256 n) external;
```

### slashingPendingForDelegator

Returns whether a delegator's stake is slashed and is pending for finalization


```solidity
function slashingPendingForDelegator(address delegator) external view returns (bool);
```

## Events
### OperatorSlashed
Emitted when a delegator's stake is slashed


```solidity
event OperatorSlashed(address indexed operator, uint256 remainingPercentage);
```

## Errors
### SlashingAmountZero

```solidity
error SlashingAmountZero();
```

### SlashingPercentageTooHigh

```solidity
error SlashingPercentageTooHigh();
```

