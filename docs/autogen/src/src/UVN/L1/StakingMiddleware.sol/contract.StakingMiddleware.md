# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3cf601aa04842b039a5cf3b59e8450ff86ee0a21/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[Notifier](/src/UVN/L1/StakingMiddleware/Notifier.sol/abstract.Notifier.md), [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)

This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.


## Functions
### constructor


```solidity
constructor(IUniStaker unistaker_, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    Notifier('UVN Staking Middleware', 'UVN');
```

### nonces

*Returns the next unused nonce for an address.*


```solidity
function nonces(address owner) public view override(Nonces, IStakingMiddleware) returns (uint256);
```

