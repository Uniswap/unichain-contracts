# INotifier
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/8c1be1ff6fd1da269c202b06cfb4eb0e104f04ef/src/interfaces/UVN/L1/StakingMiddleware/INotifier.sol)

**Inherits:**
[ISlashingManager](/src/interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol/interface.ISlashingManager.md)

This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.


## Functions
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

## Events
### URIUpdated
Emitted when the URI for a token is updated


```solidity
event URIUpdated(address indexed operator, uint256 indexed tokenId, string uri);
```

## Errors
### AlreadyMinted
Thrown when a token is already minted


```solidity
error AlreadyMinted();
```

### UnsafeTransfer
thrown when the `transferFrom` function is called


```solidity
error UnsafeTransfer();
```

### InvalidRecipient
thrown when the recipient of a safe transfer is not the operator or a contract


```solidity
error InvalidRecipient();
```

