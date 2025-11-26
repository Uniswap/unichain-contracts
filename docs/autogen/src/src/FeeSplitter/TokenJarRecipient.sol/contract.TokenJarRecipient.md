# TokenJarRecipient
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/33cb753a9dff7dc4f158cb22b7d57a8aa251fef2/src/FeeSplitter/TokenJarRecipient.sol)

A recipient contract for the NetFeeSplitter that forwards fees to a token jar


## State Variables
### NET_FEE_SPLITTER

```solidity
INetFeeSplitter private immutable NET_FEE_SPLITTER
```


### TOKEN_JAR

```solidity
address private immutable TOKEN_JAR
```


## Functions
### constructor


```solidity
constructor(address netFeeSplitter, address tokenJar) ;
```

### withdraw

Withdraws fees from the NetFeeSplitter and sends them to the token jar


```solidity
function withdraw() external returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of fees withdrawn|


