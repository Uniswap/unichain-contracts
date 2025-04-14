# IFeeSplitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/f7ee30d3904bcf7f9e6eea33683d2c2c6ac756df/src/interfaces/FeeSplitter/IFeeSplitter.sol)


## Functions
### distributeFees

Distributes the fees collected from the fee vaults to their respective destinations


```solidity
function distributeFees() external returns (bool feesDistributed);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`feesDistributed`|`bool`|Whether any fees were distributed|


### OPTIMISM_WALLET

Returns the address of the Optimism wallet


```solidity
function OPTIMISM_WALLET() external view returns (address);
```

### NET_FEE_RECIPIENT

Returns the address of the net fee recipient


```solidity
function NET_FEE_RECIPIENT() external view returns (address);
```

### L1_FEE_RECIPIENT

Returns the address of the L1 fee recipient


```solidity
function L1_FEE_RECIPIENT() external view returns (address);
```

## Events
### NoFeesCollected
Emitted when `distributeFees` is called and no fees are collected


```solidity
event NoFeesCollected();
```

### FeesDistributed
Emitted when `distributeFees` is called and fees are distributed


```solidity
event FeesDistributed(uint256 optimismShare, uint256 l1Fees, uint256 netShare);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`optimismShare`|`uint256`|The amount of fees sent to Optimism|
|`l1Fees`|`uint256`|The amount of fees sent to L1 distributor|
|`netShare`|`uint256`|The amount of fees sent to the net fee distributor|

## Errors
### AddressZero
Thrown when an address provided in the constructor is zero


```solidity
error AddressZero();
```

### TransferFailed
Thrown when a transfer fails


```solidity
error TransferFailed();
```

### Locked
Thrown an address other than the fee splitter tries to withdraw fees from vaults


```solidity
error Locked();
```

### OnlyVaults
Thrown when an address that is not a vault tries to deposit fees


```solidity
error OnlyVaults();
```

### MustWithdrawToL2
Thrown when a fee vault is configured to withdraw to L2


```solidity
error MustWithdrawToL2();
```

### MustWithdrawToFeeSplitter
Thrown when a fee vault is not configured to withdraw to the fee splitter


```solidity
error MustWithdrawToFeeSplitter();
```

