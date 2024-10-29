# IL1Splitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/ee199923a093ed2a625368ca03e88e027a4e1411/src/interfaces/FeeSplitter/IL1Splitter.sol)


## Functions
### withdraw

Withdraws the balance of the contract to L1


```solidity
function withdraw() external returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of ETH withdrawn|


### updateL1Recipient

Updates the L1 recipient


```solidity
function updateL1Recipient(address newRecipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newRecipient`|`address`|The new L1 recipient|


### updateFeeDisbursementInterval

Updates the fee disbursement interval


```solidity
function updateFeeDisbursementInterval(uint48 newInterval) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newInterval`|`uint48`|The new fee disbursement interval in seconds|


### updateMinWithdrawalAmount

Updates the minimum withdrawal amount


```solidity
function updateMinWithdrawalAmount(uint256 newAmount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newAmount`|`uint256`|The new minimum withdrawal amount|


### l1Recipient


```solidity
function l1Recipient() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The L1 recipient.|


### feeDisbursementInterval


```solidity
function feeDisbursementInterval() external view returns (uint48);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint48`|The fee disbursement interval in seconds.|


### minWithdrawalAmount


```solidity
function minWithdrawalAmount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The minimum amount of ETH that must be sent to L1.|


### lastDisbursementTime


```solidity
function lastDisbursementTime() external view returns (uint48);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint48`|The last disbursement time|


## Events
### Withdrawal
Emitted when the contract is withdrawn


```solidity
event Withdrawal(address indexed recipient, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient of the withdrawal|
|`amount`|`uint256`|The amount of ETH withdrawn|

### L1RecipientUpdated
Emitted when the L1 recipient is updated


```solidity
event L1RecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldRecipient`|`address`|The old L1 recipient|
|`newRecipient`|`address`|The new L1 recipient|

### FeeDisbursementIntervalUpdated
Emitted when the fee disbursement interval is updated


```solidity
event FeeDisbursementIntervalUpdated(uint48 oldInterval, uint48 newInterval);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldInterval`|`uint48`|The old fee disbursement interval in seconds|
|`newInterval`|`uint48`|The new fee disbursement interval in seconds|

### MinWithdrawalAmountUpdated
Emitted when the minimum withdrawal amount is updated


```solidity
event MinWithdrawalAmountUpdated(uint256 oldAmount, uint256 newAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldAmount`|`uint256`|The old minimum withdrawal amount|
|`newAmount`|`uint256`|The new minimum withdrawal amount|

## Errors
### InsufficientWithdrawalAmount
Thrown when the contract is withdrawn with an insufficient amount


```solidity
error InsufficientWithdrawalAmount();
```

### DisbursementIntervalNotReached
Thrown when the contract is withdrawn before the disbursement interval is reached


```solidity
error DisbursementIntervalNotReached();
```

### AddressZero
Thrown when the address is zero


```solidity
error AddressZero();
```

### MinDisbursementInterval
Thrown when the disbursement interval is less than the minimum disbursement interval


```solidity
error MinDisbursementInterval();
```

### MinWithdrawalAmount
Thrown when the minimum withdrawal amount is less than the minimum withdrawal amount


```solidity
error MinWithdrawalAmount();
```

