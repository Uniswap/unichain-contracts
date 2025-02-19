# FeeSplitter
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/01f4e5565a975be8c899959d029a1dc7e641a28e/src/FeeSplitter/FeeSplitter.sol)

**Inherits:**
[IFeeSplitter](/src/interfaces/FeeSplitter/IFeeSplitter.sol/interface.IFeeSplitter.md)

*Withdraws funds from system FeeVault contracts, shares revenue with Optimism, sends remaining revenue to L1 and net fee recipients*


## State Variables
### LOCK_STORAGE_SLOT

```solidity
bytes32 private constant LOCK_STORAGE_SLOT = 0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e91;
```


### NET_REVENUE_STORAGE_SLOT

```solidity
bytes32 private constant NET_REVENUE_STORAGE_SLOT = 0x784be9e5da62c580888dd777e3d4e36ef68053ef5af2fc8f65c4050e4729e434;
```


### BASIS_POINT_SCALE

```solidity
uint32 internal constant BASIS_POINT_SCALE = 1000;
```


### NET_REVENUE_SHARE

```solidity
uint32 internal constant NET_REVENUE_SHARE = 150;
```


### GROSS_REVENUE_SHARE

```solidity
uint32 internal constant GROSS_REVENUE_SHARE = 25;
```


### OPTIMISM_WALLET
*The address of the Optimism wallet that will receive Optimism's revenue share.*


```solidity
address public immutable OPTIMISM_WALLET;
```


### NET_FEE_RECIPIENT
*The address of the Rewards Distributor that will receive a share of fees;*


```solidity
address public immutable NET_FEE_RECIPIENT;
```


### L1_FEE_RECIPIENT
*The address of the L1 wallet that will receive the OP chain runner's share of fees.*


```solidity
address public immutable L1_FEE_RECIPIENT;
```


## Functions
### constructor

*Constructor for the FeeSplitter contract which validates and sets immutable variables.*


```solidity
constructor(address optimismWallet, address l1FeeRecipient, address netFeeRecipient);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`optimismWallet`|`address`|The address which receives Optimism's revenue share.|
|`l1FeeRecipient`|`address`|The address which receives the L1 fee share.|
|`netFeeRecipient`|`address`|The address which receives the net fee share.|


### distributeFees

Distributes the fees collected from the fee vaults to their respective destinations


```solidity
function distributeFees() external virtual returns (bool feesDistributed);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`feesDistributed`|`bool`|Whether any fees were distributed|


### receive

*Receives ETH fees withdrawn from L2 FeeVaults and stores the net revenue in transient storage.*

*Will revert if ETH is not sent from L2 FeeVaults.*

*anyone can call the withdraw function on the vaults, the lock ensures that a withdrawal is only successful if the fee splitter is withdrawing the fees to ensure accurate accounting*


```solidity
receive() external payable virtual;
```

### _feeVaultWithdrawal


```solidity
function _feeVaultWithdrawal(address _feeVault) internal;
```

