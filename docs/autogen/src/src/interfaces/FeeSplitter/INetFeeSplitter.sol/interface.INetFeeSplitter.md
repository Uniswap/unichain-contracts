# INetFeeSplitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/a1d3e2da21a1281f5cbf2a247c8426504035b002/src/interfaces/FeeSplitter/INetFeeSplitter.sol)


## Functions
### transferAllocation

Transfers a allocation from one recipient to another

*reverts if the recipient doesn't have an admin*


```solidity
function transferAllocation(address from, address recipient, uint256 allocation) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The recipient address to transfer from|
|`recipient`|`address`|The recipient address to transfer to|
|`allocation`|`uint256`|The allocation to transfer|


### transferAllocationAndSetSetter

Transfers the allocation of a recipient to another recipient and sets the setter of the recipient

*reverts if the recipient already has a setter*


```solidity
function transferAllocationAndSetSetter(address from, address recipient, address newAdmin, uint256 allocation)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The recipient address to transfer from|
|`recipient`|`address`|The recipient address to transfer to|
|`newAdmin`|`address`|The new setter address for the recipient|
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
function balanceOf(address recipient) external view returns (uint256);
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
function setterOf(address recipient) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|setter The setter of the recipient|


## Events
### AllocationTransferred
Emitted when a recipient's allocation is transferred


```solidity
event AllocationTransferred(address indexed setter, address indexed from, address indexed to, uint256 allocation);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`setter`|`address`|The setter address managing the recipient|
|`from`|`address`|The previous recipient address|
|`to`|`address`|The new recipient address|
|`allocation`|`uint256`|The allocation transferred|

### SetterTransferred
Emitted when a recipient's setter is transferred


```solidity
event SetterTransferred(address indexed recipient, address indexed previousSetter, address indexed newSetter);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|
|`previousSetter`|`address`|The previous setter address|
|`newSetter`|`address`|The new setter address|

### Withdrawn
Emitted when fees are withdrawn by recipient


```solidity
event Withdrawn(address indexed recipient, address indexed to, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|
|`to`|`address`|The address the fees were withdrawn to|
|`amount`|`uint256`|The amount of fees withdrawn|

## Errors
### InvalidRecipients
Thrown when the recipients array is not the same length as the recipientData array


```solidity
error InvalidRecipients();
```

### DuplicateRecipient
Thrown when a duplicate recipient is added


```solidity
error DuplicateRecipient();
```

### SetterZero
Thrown when an setter address is zero


```solidity
error SetterZero();
```

### SetterAlreadySet
Thrown when a recipient already has a setter


```solidity
error SetterAlreadySet();
```

### RecipientZero
Thrown when a recipient address is zero


```solidity
error RecipientZero();
```

### AllocationZero
Thrown when a recipient allocation is zero or zero allocation is transferred


```solidity
error AllocationZero();
```

### InvalidTotalAllocation
Thrown when the total allocation is not the same as the sum of the recipient balances


```solidity
error InvalidTotalAllocation();
```

### Unauthorized
Thrown when the caller is not the setter


```solidity
error Unauthorized();
```

### InsufficientAllocation
Thrown when there is insufficient allocation to perform a transfer


```solidity
error InsufficientAllocation();
```

### WithdrawalFailed
Thrown when a withdrawal fails


```solidity
error WithdrawalFailed();
```

## Structs
### Recipient
Recipient data for an individual recipient

**Notes:**
- setter The setter address managing the recipient

- allocation The allocation of the recipient


```solidity
struct Recipient {
    address setter;
    uint256 allocation;
}
```

