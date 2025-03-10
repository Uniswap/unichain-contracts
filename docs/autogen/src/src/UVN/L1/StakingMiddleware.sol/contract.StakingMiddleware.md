# StakingMiddleware
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/UVN/L1/StakingMiddleware.sol)

**Inherits:**
[SlashingManager](/src/UVN/L1/StakingMiddleware/SlashingManager.sol/abstract.SlashingManager.md), [IStakingMiddleware](/src/interfaces/UVN/L1/IStakingMiddleware.sol/interface.IStakingMiddleware.md)


## Functions
### constructor


```solidity
constructor(IUniStaker unistaker_, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    UniStakerWrapper(unistaker_, initialAdmin, withdrawalDelay_, slashingBeneficiary_);
```

### nonces

*Returns the next unused nonce for an address.*


```solidity
function nonces(address owner) public view override(Nonces, IStakingMiddleware) returns (uint256);
```

