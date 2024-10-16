# IL1Splitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/01f4e5565a975be8c899959d029a1dc7e641a28e/src/interfaces/FeeSplitter/IL1Splitter.sol)


## Functions
### withdraw

Withdraws the balance of the contract to L1


```solidity
function withdraw() external;
```

## Events
### Withdrawal
Emitted when the contract is withdrawn


```solidity
event Withdrawal(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of ETH withdrawn|

## Errors
### InsufficientWithdrawalAmount
Thrown when the contract is withdrawn with an insufficient amount


```solidity
error InsufficientWithdrawalAmount();
```

### DisbursementIntervalNotReached
Thrown when the contract is withdrawn before the disbursement interval is reached


```solidity
error DisbursementIntervalNotReached();
```

