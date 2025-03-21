# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/83905ef6205bbfaf59409691913db2875c92ada2/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[SlashingManager](/src/UVN/L1/StakingMiddleware/SlashingManager.sol/abstract.SlashingManager.md), [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)

This contract is the main staking contract for the Unichain Validator Network (UVN). It allows delegators to stake UNI, deposit their underlying staked UNI into the UniStaker contract to participate in UNI governance and accrue protocol fees, and choose an operator to delegate their stake to.


## Functions
### constructor


```solidity
constructor(IUniStaker unistaker_, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_);
```

### nonces

*The `Nonces` library does not come with an interface, to ensure that the function is included in the interface of this contract, add it here*


```solidity
function nonces(address owner) public view override(Nonces, IStakingMiddleware) returns (uint256);
```

