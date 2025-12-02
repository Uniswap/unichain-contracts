# L1NetRecipient
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/0ef8c116535322474dee36aa6e19ce89142633be/src/FeeSplitter/L1NetRecipient.sol)

**Inherits:**
[L1Splitter](/Users/eric.zhong/uniswap/unichain-contracts/docs/autogen/src/src/FeeSplitter/L1Splitter.sol/contract.L1Splitter.md)

Pulls fees from the `NetFeeSplitter` and withdraws them to L1


## State Variables
### NET_FEE_SPLITTER

```solidity
INetFeeSplitter private immutable NET_FEE_SPLITTER
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

