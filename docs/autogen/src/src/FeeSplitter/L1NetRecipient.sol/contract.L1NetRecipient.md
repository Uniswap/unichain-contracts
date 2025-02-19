# L1NetRecipient
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/7d082d43521bcb905aa20ba11b80b16647dcf7ef/src/FeeSplitter/L1NetRecipient.sol)

**Inherits:**
[L1Splitter](/src/FeeSplitter/L1Splitter.sol/contract.L1Splitter.md)

Pulls fees from the `NetFeeSplitter` and withdraws them to L1


## State Variables
### NET_FEE_SPLITTER

```solidity
INetFeeSplitter private immutable NET_FEE_SPLITTER;
```


## Functions
### constructor


```solidity
constructor(
    address netFeeSplitter,
    address initialOwner,
    address l1Wallet,
    uint48 feeDisbursementInterval_,
    uint256 minWithdrawalAmount_
) L1Splitter(initialOwner, l1Wallet, feeDisbursementInterval_, minWithdrawalAmount_);
```

### withdraw


```solidity
function withdraw() public override returns (uint256 balance);
```

