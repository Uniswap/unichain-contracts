# NetFeeSplitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/01f4e5565a975be8c899959d029a1dc7e641a28e/src/FeeSplitter/NetFeeSplitter.sol)

**Inherits:**
[INetFeeSplitter](/src/interfaces/FeeSplitter/INetFeeSplitter.sol/interface.INetFeeSplitter.md)

Splits net fees between multiple recipients. Recipients are managed by admins. Admins can transfer the entire allocation or a portion of it to other recipients.


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


### transferAdmin

Transfers the admin of a recipient to a new admin


```solidity
function transferAdmin(address recipient, address newAdmin) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|
|`newAdmin`|`address`|The new admin address|


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


### adminOf

Gets the admin of a recipient


```solidity
function adminOf(address recipient) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|admin The admin of the recipient|


### _calculateFees


```solidity
function _calculateFees(address account) private view returns (uint256);
```

### _updateFees


```solidity
function _updateFees(address account) private;
```

