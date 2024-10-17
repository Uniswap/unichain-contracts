# IFeeVault
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3b755215379388bda78294afb56d7288557e61d0/src/interfaces/optimism/IFeeVault.sol)

from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/universal/FeeVault.sol


## Functions
### WITHDRAWAL_NETWORK

Network which the recipient will receive fees on.
Use the `withdrawalNetwork()` getter as this is deprecated
and is subject to be removed in the future.


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


```solidity
enum WithdrawalNetwork {
    L1,
    L2
}
```

