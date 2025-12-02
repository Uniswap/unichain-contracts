# FeeRecipientForwarder
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/0ef8c116535322474dee36aa6e19ce89142633be/src/FeeSplitter/FeeRecipientForwarder.sol)

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


