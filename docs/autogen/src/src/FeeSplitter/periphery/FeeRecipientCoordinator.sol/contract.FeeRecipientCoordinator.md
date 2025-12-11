# FeeRecipientCoordinator
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/abab1dab5c3da5c73350d0ee6dcecbaa4471f609/src/FeeSplitter/periphery/FeeRecipientCoordinator.sol)

**Title:**
FeeRecipientCoordinator

A helper contract to withdraw fees from multiple FeeRecipientForwarders in one transaction


## State Variables
### feeRecipientForwarders

```solidity
IFeeRecipientForwarder[] private feeRecipientForwarders
```


## Functions
### constructor


```solidity
constructor(IFeeRecipientForwarder[] memory _feeRecipientForwarders) ;
```

### withdraw

Withdraws fees from all FeeRecipientForwarders

This function will fail if any of the inner withdrawals revert


```solidity
function withdraw() external returns (uint256 totalAmount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalAmount`|`uint256`|The total amount of fees withdrawn|


