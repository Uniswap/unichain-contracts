# NetFeeSplitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/0d11217a8d1ea234543e2ac46c4298f0b5f3b3f8/src/FeeSplitter/NetFeeSplitter.sol)

**Inherits:**
[INetFeeSplitter](/src/interfaces/FeeSplitter/INetFeeSplitter.sol/interface.INetFeeSplitter.md)

Splits net fees between multiple recipients. Recipients are managed by setters. Setters can transfer the entire allocation or a portion of it to other recipients.


## State Variables
### TOTAL_ALLOCATION

```solidity
uint256 internal constant TOTAL_ALLOCATION = 10_000;
```


### MAGNITUDE

```solidity
uint256 private constant MAGNITUDE = 1e30;
```


### _index

```solidity
uint256 private _index;
```


### _indexOf

```solidity
mapping(address recipient => uint256 index) private _indexOf;
```


### _earned

```solidity
mapping(address recipient => uint256 _earned) private _earned;
```


### recipients

```solidity
mapping(address recipient => Recipient) public recipients;
```


## Functions
### constructor


```solidity
constructor(address[] memory initialRecipients, Recipient[] memory recipientData);
```

### receive

*Keep track of incoming fees*


```solidity
receive() external payable;
```

### transfer

Transfers a allocation from one recipient to another


```solidity
function transfer(address from, address recipient, uint256 allocation) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The recipient address to transfer from|
|`recipient`|`address`|The recipient address to transfer to|
|`allocation`|`uint256`|The allocation to transfer|


### transferSetter

Transfers the setter of a recipient to a new setter


```solidity
function transferSetter(address recipient, address newSetter) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|
|`newSetter`|`address`|The new setter address|


### withdrawFees

Withdraws the fees earned by a recipient


```solidity
function withdrawFees(address to) external returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to withdraw the fees to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of fees withdrawn|


### earnedFees

Calculates the fees earned by a recipient


```solidity
function earnedFees(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The recipient address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount The amount of fees earned|


### balanceOf

Gets the allocation of a recipient


```solidity
function balanceOf(address recipient) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|allocation The allocation of the recipient|


### setterOf

Gets the setter of a recipient


```solidity
function setterOf(address recipient) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|setter The setter of the recipient|


### _calculateFees


```solidity
function _calculateFees(address account) private view returns (uint256);
```

### _updateFees


```solidity
function _updateFees(address account) private;
```

