# ISlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol)

**Inherits:**
[IDelegatorAccessControl](/src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol/interface.IDelegatorAccessControl.md)

This contract manages the slashing of delegators and operators. When operators are slashed, the slashed amount is converted into the remaining percentage of the operator's slashable delegated stake. The voting power of the operator is updated immediately. As delegators have their own deposits into the UniStaker contract, slashing is applied to the delegator's slashable stake when the delegator next interacts with the StakingMiddleware contract. Slashing can also be applied by anyone at any time. To ensure there isn't an incentive to not stay slashed and continue accruing protocol fees in the UniStaker contract, rewards accrued by the delegator are also slashed.


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

### SLASHER_ROLE

Returns the role for slashers


```solidity
function SLASHER_ROLE() external view returns (bytes32);
```

## Events
### OperatorSlashed
Emitted when a delegator's stake is slashed


```solidity
event OperatorSlashed(address indexed operator, uint256 remainingPercentage);
```

## Errors
### SlashingAmountZero
Thrown when an attempt is made to slash zero stake


```solidity
error SlashingAmountZero();
```

### SlashingPercentageTooHigh
Thrown when a slashing percentage exceeds 100%


```solidity
error SlashingPercentageTooHigh();
```

### AddressZero
When the zero address is slashed


```solidity
error AddressZero();
```

