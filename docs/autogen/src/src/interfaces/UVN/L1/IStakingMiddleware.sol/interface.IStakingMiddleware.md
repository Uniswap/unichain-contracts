# IStakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3cf601aa04842b039a5cf3b59e8450ff86ee0a21/src/interfaces/UVN/L1/IStakingMiddleware.sol)

**Inherits:**
[INotifier](/src/interfaces/UVN/L1/StakingMiddleware/INotifier.sol/interface.INotifier.md)

This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.


## Functions
### nonces

Returns the nonces used for delegation by signature


```solidity
function nonces(address owner) external view returns (uint256);
```

