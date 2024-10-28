# L1Splitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/cdc1949bdb3dee7a056f4123f4443d9d835fc39d/src/FeeSplitter/L1Splitter.sol)

**Inherits:**
[IL1Splitter](/src/interfaces/FeeSplitter/IL1Splitter.sol/interface.IL1Splitter.md), Ownable2Step

Withdraws the L1 fees to the L1 wallet via the L2 Standard Bridge.


## State Variables
### WITHDRAWAL_MIN_GAS
*The minimum gas limit for the FeeSplitter withdrawal transaction to L1.*


```solidity
uint32 internal constant WITHDRAWAL_MIN_GAS = 35_000;
```


### lastDisbursementTime

```solidity
uint48 public lastDisbursementTime;
```


### l1Recipient

```solidity
address public l1Recipient;
```


### feeDisbursementInterval

```solidity
uint48 public feeDisbursementInterval;
```


### minWithdrawalAmount

```solidity
uint256 public minWithdrawalAmount;
```


## Functions
### constructor


```solidity
constructor(address initialOwner, address l1Wallet, uint48 feeDisbursementInterval_, uint256 minWithdrawalAmount_)
    Ownable(initialOwner);
```

### withdraw

Withdraws the balance of the contract to L1


```solidity
function withdraw() public virtual returns (uint256 balance);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`uint256`|The amount of ETH withdrawn|


### updateL1Recipient

Updates the L1 recipient


```solidity
function updateL1Recipient(address newRecipient) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newRecipient`|`address`|The new L1 recipient|


### updateFeeDisbursementInterval

Updates the fee disbursement interval


```solidity
function updateFeeDisbursementInterval(uint48 newInterval) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newInterval`|`uint48`|The new fee disbursement interval in seconds|


### updateMinWithdrawalAmount

Updates the minimum withdrawal amount


```solidity
function updateMinWithdrawalAmount(uint256 newAmount) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newAmount`|`uint256`|The new minimum withdrawal amount|


### _updateL1Recipient


```solidity
function _updateL1Recipient(address newRecipient) internal;
```

### _updateFeeDisbursementInterval


```solidity
function _updateFeeDisbursementInterval(uint48 newInterval) internal;
```

### _updateMinWithdrawalAmount


```solidity
function _updateMinWithdrawalAmount(uint256 newAmount) internal;
```

### receive


```solidity
receive() external payable;
```

