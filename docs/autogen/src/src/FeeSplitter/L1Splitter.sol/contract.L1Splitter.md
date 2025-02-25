# L1Splitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/ee199923a093ed2a625368ca03e88e027a4e1411/src/FeeSplitter/L1Splitter.sol)

**Inherits:**
[IL1Splitter](/src/interfaces/FeeSplitter/IL1Splitter.sol/interface.IL1Splitter.md), Ownable2Step

Withdraws the L1 fees to the L1 wallet via the L2 Standard Bridge.


## State Variables
### WITHDRAWAL_MIN_GAS
*The minimum gas limit for the FeeSplitter withdrawal transaction to L1.*


```solidity
uint32 internal constant WITHDRAWAL_MIN_GAS = 35_000;
```


### MIN_DISBURSEMENT_INTERVAL

```solidity
uint48 internal constant MIN_DISBURSEMENT_INTERVAL = 10 minutes;
```


### MIN_WITHDRAWAL_AMOUNT

```solidity
uint256 internal constant MIN_WITHDRAWAL_AMOUNT = 0.01 ether;
```


### l1Recipient

```solidity
address public l1Recipient;
```


### feeDisbursementInterval

```solidity
uint48 public feeDisbursementInterval;
```


### lastDisbursementTime

```solidity
uint48 public lastDisbursementTime;
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

