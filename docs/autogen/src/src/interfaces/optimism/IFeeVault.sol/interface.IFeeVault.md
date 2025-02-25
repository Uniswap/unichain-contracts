# IFeeVault
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/01b16016c9ca0bdf466dccf23f199a62de47a78e/src/interfaces/optimism/IFeeVault.sol)

from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/universal/FeeVault.sol


## Functions
### WITHDRAWAL_NETWORK

Network which the recipient will receive fees on.
Use the `withdrawalNetwork()` getter as this is deprecated
and is subject to be removed in the future.

**Note:**
legacy: 


```solidity
function WITHDRAWAL_NETWORK() external view returns (WithdrawalNetwork);
```

### withdrawalNetwork


```solidity
function withdrawalNetwork() external view returns (WithdrawalNetwork);
```

### RECIPIENT

Account that will receive the fees. Can be located on L1 or L2.
Use the `recipient()` getter as this is deprecated
and is subject to be removed in the future.

**Note:**
legacy: 


```solidity
function RECIPIENT() external view returns (address);
```

### recipient


```solidity
function recipient() external view returns (address);
```

### MIN_WITHDRAWAL_AMOUNT

Minimum balance before a withdrawal can be triggered.
Use the `minWithdrawalAmount()` getter as this is deprecated
and is subject to be removed in the future.

**Note:**
legacy: 


```solidity
function MIN_WITHDRAWAL_AMOUNT() external view returns (uint256);
```

### minWithdrawalAmount


```solidity
function minWithdrawalAmount() external view returns (uint256);
```

### withdraw

Triggers a withdrawal of funds to the fee wallet on L1 or L2.


```solidity
function withdraw() external;
```

## Enums
### WithdrawalNetwork
Enum representing where the FeeVault withdraws funds to.

**Notes:**
- value: L1 FeeVault withdraws funds to L1.

- value: L2 FeeVault withdraws funds to L2.


```solidity
enum WithdrawalNetwork {
    L1,
    L2
}
```

