# Notifier
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/8c1be1ff6fd1da269c202b06cfb4eb0e104f04ef/src/UVN/L1/StakingMiddleware/Notifier.sol)

**Inherits:**
[SlashingManager](/src/UVN/L1/StakingMiddleware/SlashingManager.sol/abstract.SlashingManager.md), ERC721, [INotifier](/src/interfaces/UVN/L1/StakingMiddleware/INotifier.sol/interface.INotifier.md)

This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.


## State Variables
### _uris

```solidity
mapping(address operator => string uri) private _uris;
```


## Functions
### constructor


```solidity
constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) OperatorManager(name_);
```

### mint

Allows an operator to mint a new token to deposit into service contracts


```solidity
function mint() external;
```

### setURI

Allows an operator to set the URI for their token


```solidity
function setURI(string memory uri) external;
```

### tokenURI


```solidity
function tokenURI(uint256 tokenId) public view virtual override returns (string memory);
```

### transferFrom

*disallow unsafe transfers*


```solidity
function transferFrom(address, address, uint256) public pure override;
```

### safeTransferFrom

*only allow transfers to contracts and the operator*


```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override;
```

### _isContract


```solidity
function _isContract(address account) private view returns (bool);
```

### _toTokenId


```solidity
function _toTokenId(address owner) private pure returns (uint256);
```

### _toAddress


```solidity
function _toAddress(uint256 tokenId) private pure returns (address);
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool);
```

