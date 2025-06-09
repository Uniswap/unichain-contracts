# IDelegatorClaim
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/interfaces/UVN/L2/IDelegatorClaim.sol)

This interface is used for delegator reward distribution. Operators can override the default delegator claim contract with a custom contract that implements this interface.


## Functions
### reportDelegatorStake

Reports a delegator stake to the reward distributor contract

*MUST revert if the caller is not the L2 stake table sync contract*

*When an operator is slashed, delegator stakes are only updated when slashing is applied on L1*


```solidity
function reportDelegatorStake(address delegator, uint256 newStake) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|The address of the delegator|
|`newStake`|`uint256`|The new stake of the delegator|


