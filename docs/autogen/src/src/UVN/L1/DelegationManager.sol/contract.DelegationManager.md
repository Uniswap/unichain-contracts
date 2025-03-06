# DelegationManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/6b285bfe59012065422d5d75fc08ddb0d2404ce9/src/UVN/L1/DelegationManager.sol)

**Inherits:**
ERC20Votes, [IDelegationManager](/src/interfaces/UVN/L1/IDelegationManager.sol/interface.IDelegationManager.md), Ownable


## Functions
### constructor


```solidity
constructor(address initialAdmin)
    ERC20('UNI DelegationManager', 'UNI-DM')
    EIP712('UNI DelegationManager', '1')
    Ownable(initialAdmin);
```

### _update


```solidity
function _update(address from, address to, uint256 value) internal override;
```

### mint


```solidity
function mint(address to, uint256 amount) external onlyOwner;
```

### burn


```solidity
function burn(address from, uint256 amount) external onlyOwner;
```

### updateDelegatee


```solidity
function updateDelegatee(address account, address newDelegatee) external onlyOwner;
```

