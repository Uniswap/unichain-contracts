# IFeeRecipientForwarder
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/abab1dab5c3da5c73350d0ee6dcecbaa4471f609/src/interfaces/periphery/IFeeRecipientForwarder.sol)

**Title:**
IFeeRecipientForwarder

Interface for the FeeRecipientForwarder contract


## Functions
### withdraw

Withdraws fees from the NetFeeSplitter and sends them to the recipient


```solidity
function withdraw() external returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of fees withdrawn|


