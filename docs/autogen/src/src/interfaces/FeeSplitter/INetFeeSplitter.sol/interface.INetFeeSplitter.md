# INetFeeSplitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3b755215379388bda78294afb56d7288557e61d0/src/interfaces/FeeSplitter/INetFeeSplitter.sol)


## Functions
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


### adminOf

Gets the admin of a recipient


```solidity
function adminOf(address recipient) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|admin The admin of the recipient|


## Events
### TransferAllocation
Emitted when a recipient's allocation is transferred


```solidity
event TransferAllocation(address indexed admin, address indexed from, address indexed to, uint256 allocation);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin`|`address`|The admin address managing the recipient|
|`from`|`address`|The previous recipient address|
|`to`|`address`|The new recipient address|
|`allocation`|`uint256`|The allocation transferred|

### TransferAdmin
Emitted when a recipient's admin is transferred


```solidity
event TransferAdmin(address indexed recipient, address indexed previousAdmin, address indexed newAdmin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|
|`previousAdmin`|`address`|The previous admin address|
|`newAdmin`|`address`|The new admin address|

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

### AdminZero
Thrown when an admin address is zero


```solidity
error AdminZero();
```

### RecipientZero
Thrown when a recipient address is zero


```solidity
error RecipientZero();
```

### AllocationZero
Thrown when a recipient allocation is zero


```solidity
error AllocationZero();
```

### InvalidTotalAllocation
Thrown when the total allocation is not the same as the sum of the recipient balances


```solidity
error InvalidTotalAllocation();
```

### Unauthorized
Thrown when the caller is not the admin


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


```solidity
struct Recipient {
    address admin;
    uint256 allocation;
}
```

