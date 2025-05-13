# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[Notifier](/src/UVN/L1/StakingMiddleware/Notifier.sol/abstract.Notifier.md), Multicall, [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)

This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.

**Note:**
security-contact: security@uniswap.org


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

