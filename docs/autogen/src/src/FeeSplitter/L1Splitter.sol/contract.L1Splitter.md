# L1Splitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/01f4e5565a975be8c899959d029a1dc7e641a28e/src/FeeSplitter/L1Splitter.sol)

**Inherits:**
[IL1Splitter](/src/interfaces/FeeSplitter/IL1Splitter.sol/interface.IL1Splitter.md)

Withdraws the L1 fees to the L1 wallet via the L2 Standard Bridge.


## State Variables
### WITHDRAWAL_MIN_GAS
*The minimum gas limit for the FeeSplitter withdrawal transaction to L1.*


```solidity
uint32 internal constant WITHDRAWAL_MIN_GAS = 35_000;
```


### WITHDRAWAL_MIN_AMOUNT
*The minimum amount of ETH that must be sent to L1.*


```solidity
uint256 internal constant WITHDRAWAL_MIN_AMOUNT = 0.1 ether;
```


### L1_WALLET

```solidity
address internal immutable L1_WALLET;
```


### FEE_DISBURSEMENT_INTERVAL

```solidity
uint256 internal immutable FEE_DISBURSEMENT_INTERVAL;
```


### lastDisbursementTime

```solidity
uint256 public lastDisbursementTime;
```


## Functions
### constructor


```solidity
constructor(address l1Wallet, uint256 feeDisbursementInterval);
```

### withdraw

Withdraws the balance of the contract to L1


```solidity
function withdraw() external;
```

### receive


```solidity
receive() external payable;
```

