# FeeRecipientForwarder
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/abab1dab5c3da5c73350d0ee6dcecbaa4471f609/src/FeeSplitter/periphery/FeeRecipientForwarder.sol)

**Inherits:**
[IFeeRecipientForwarder](/src/interfaces/periphery/IFeeRecipientForwarder.sol/interface.IFeeRecipientForwarder.md)

**Title:**
Fee Recipient Forwarder

A recipient contract for the NetFeeSplitter that forwards fees to another recipient


## State Variables
### NET_FEE_SPLITTER

```solidity
INetFeeSplitter private immutable NET_FEE_SPLITTER
```


### RECIPIENT

```solidity
address private immutable RECIPIENT
```


## Functions
### constructor


```solidity
constructor(address netFeeSplitter, address recipient) ;
```

### withdraw

Withdraws fees from the NetFeeSplitter and sends them to the recipient


```solidity
function withdraw() external returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of fees withdrawn|


