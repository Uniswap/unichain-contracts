# IStakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/43cfeb46627ac8e6e7739462906618c85350c785/src/interfaces/UVN/L1/IStakingMiddleware.sol)

**Inherits:**
[ISlashingManager](/src/interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol/interface.ISlashingManager.md)

This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.


## Functions
### nonces

Returns the nonces used for delegation by signature


```solidity
function nonces(address owner) external view returns (uint256);
```

