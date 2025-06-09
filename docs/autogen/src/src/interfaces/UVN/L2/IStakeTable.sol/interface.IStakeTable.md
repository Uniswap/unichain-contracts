# IStakeTable
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/interfaces/UVN/L2/IStakeTable.sol)

**Inherits:**
IVotes

The reward distributor contract pulls voting weights and the beneficiary for reward distribution from contracts implementing this interface.


## Functions
### beneficiary

Returns the beneficiary address to receive rewards for the given operator address


```solidity
function beneficiary(address operator) external view returns (address);
```

