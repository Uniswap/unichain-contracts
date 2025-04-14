# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[Notifier](/src/UVN/L1/StakingMiddleware/Notifier.sol/abstract.Notifier.md), Multicall, [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)

This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.


## Functions
### constructor


```solidity
constructor(IUniStaker unistaker_, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_)
    Notifier('UVN Staking Middleware', 'UVN');
```

### nonces

*The `Nonces` library does not come with an interface, to ensure that the function is included in the interface of this contract, add it here*


```solidity
function nonces(address owner) public view override(Nonces, IStakingMiddleware) returns (uint256);
```

