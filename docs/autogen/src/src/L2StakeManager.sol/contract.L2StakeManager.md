# L2StakeManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/2b39a73852bb4fead37417039aa931063fb8280f/src/L2StakeManager.sol)

**Inherits:**
ERC20Votes

The L2StakeManager is a token that keeps track of the L1 stake of an attester on L2.


## State Variables
### MESSENGER

```solidity
IL2CrossDomainMessenger internal constant MESSENGER =
    IL2CrossDomainMessenger(0x4200000000000000000000000000000000000007);
```


### L1_STAKE_MANAGER

```solidity
address internal immutable L1_STAKE_MANAGER;
```


## Functions
### onlyL1StakeManager


```solidity
modifier onlyL1StakeManager();
```

### constructor


```solidity
constructor(address l1StakeManager) ERC20('L2 Stake Manager', 'L2SM') EIP712('L2StakeManager', '1');
```

### registerDeposit


```solidity
function registerDeposit(address user, uint256 amount) external onlyL1StakeManager;
```

### registerWithdrawal


```solidity
function registerWithdrawal(address user, uint256 amount) external onlyL1StakeManager;
```

### _update


```solidity
function _update(address from, address to, uint256 amount) internal override;
```

## Errors
### Unauthorized

```solidity
error Unauthorized();
```

### TransfersDisabled

```solidity
error TransfersDisabled();
```

