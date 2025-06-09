# IL2StakeTable
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/interfaces/UVN/L2/IL2StakeTable.sol)

**Inherits:**
[IBaseService](/src/interfaces/UVN/IBaseService.sol/interface.IBaseService.md), [IStakeTable](/src/interfaces/UVN/L2/IStakeTable.sol/interface.IStakeTable.md), [IERC7751](/src/interfaces/IERC7751.sol/interface.IERC7751.md)

This contract is a clone of the L1 stake table. Whenever the balance of an operator changes on L1, this contract is notified and the balance is updated on L2. This contract deploys a default contract for delegators to claim rewards when the ERC-721 token is deposited on L1. This contract is then notified of subsequent stake changes on L1. Operators can override the default delegator claim contract with a custom implementation to distribute rewards differently.


## Functions
### overrideDelegatorClaimContract

Sets a delegator claim contract for an operator

*Allows an operator to override the default delegator claim contract with a custom implementation*


```solidity
function overrideDelegatorClaimContract(IDelegatorClaim delegatorClaim) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegatorClaim`|`IDelegatorClaim`|The delegator claim contract to set|


## Events
### DelegatorClaimContractSet
Emitted when an operator sets a delegator claim contract


```solidity
event DelegatorClaimContractSet(address indexed operator, IDelegatorClaim delegatorClaim);
```

### DelegatorStakeUpdateFailed
Emitted when a delegator stake update fails


```solidity
event DelegatorStakeUpdateFailed(address indexed operator, address delegator, bytes reason);
```

## Errors
### NotStakeTableSync
Thrown when the caller is not the L1 stake table sync contract


```solidity
error NotStakeTableSync();
```

### DelegationDisabled
Thrown when a delegation is attempted


```solidity
error DelegationDisabled();
```

### OnlyCallableBySelf
Thrown when the caller is not the L2 stake table contract


```solidity
error OnlyCallableBySelf();
```

### ZeroAddress
Thrown when the delegator claim contract is set to a zero address


```solidity
error ZeroAddress();
```

### NoCode
Thrown when the delegator claim contract has no code


```solidity
error NoCode();
```

