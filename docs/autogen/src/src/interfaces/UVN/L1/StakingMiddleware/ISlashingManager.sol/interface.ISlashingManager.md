# ISlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/07d4bd0c93642e180d59fb2de755cf59c8c044e6/src/interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol)

**Inherits:**
[IDelegatorAccessControl](/src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol/interface.IDelegatorAccessControl.md)


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

