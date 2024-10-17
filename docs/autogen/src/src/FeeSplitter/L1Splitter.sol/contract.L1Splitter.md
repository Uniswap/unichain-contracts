# L1Splitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3b755215379388bda78294afb56d7288557e61d0/src/FeeSplitter/L1Splitter.sol)

**Inherits:**
[IL1Splitter](/src/interfaces/FeeSplitter/IL1Splitter.sol/interface.IL1Splitter.md)

Withdraws the L1 fees to the L1 wallet via the L2 Standard Bridge.


## State Variables
### WITHDRAWAL_MIN_GAS
*The minimum gas limit for the FeeSplitter withdrawal transaction to L1.*


```solidity
uint32 internal constant WITHDRAWAL_MIN_GAS = 35_000;
```


### L1_WALLET

```solidity
address internal immutable L1_WALLET;
```


### FEE_DISBURSEMENT_INTERVAL

```solidity
uint256 internal immutable FEE_DISBURSEMENT_INTERVAL;
```


### WITHDRAWAL_MIN_AMOUNT
*The minimum amount of ETH that must be sent to L1.*


```solidity
uint256 internal immutable WITHDRAWAL_MIN_AMOUNT;
```


### lastDisbursementTime

```solidity
uint256 public lastDisbursementTime;
```


## Functions
### constructor


```solidity
constructor(address l1Wallet, uint256 feeDisbursementInterval, uint256 withdrawalMinAmount);
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

