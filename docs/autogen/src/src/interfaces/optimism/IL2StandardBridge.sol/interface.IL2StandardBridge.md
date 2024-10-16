# IL2StandardBridge
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/01f4e5565a975be8c899959d029a1dc7e641a28e/src/interfaces/optimism/IL2StandardBridge.sol)


## Functions
### bridgeETHTo

Sends ETH to a receiver's address on the other chain. Note that if ETH is sent to a
smart contract and the call fails, the ETH will be temporarily locked in the
StandardBridge on the other chain until the call is replayed. If the call cannot be
replayed with any amount of gas (call always reverts), then the ETH will be
permanently locked in the StandardBridge on the other chain. ETH will also
be locked if the receiver is the other bridge, because finalizeBridgeETH will revert
in that case.


```solidity
function bridgeETHTo(address _to, uint32 _minGasLimit, bytes calldata _extraData) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|         Address of the receiver.|
|`_minGasLimit`|`uint32`|Minimum amount of gas that the bridge can be relayed with.|
|`_extraData`|`bytes`|  Extra data to be sent with the transaction. Note that the recipient will not be triggered with this data, but it will be emitted and can be used to identify the transaction.|


