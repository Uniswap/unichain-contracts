# Notifier
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/7dcfc053062e80b4db9d2b818e627cd6f4a79851/src/UVN/L1/StakingMiddleware/Notifier.sol)

**Inherits:**
[SlashingManager](/src/UVN/L1/StakingMiddleware/SlashingManager.sol/abstract.SlashingManager.md), ERC721, [INotifier](/src/interfaces/UVN/L1/StakingMiddleware/INotifier.sol/interface.INotifier.md)

This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.


## State Variables
### MIN_GAS

```solidity
uint256 private constant MIN_GAS = 500_000;
```


### _uris

```solidity
mapping(address operator => string uri) private _uris;
```


## Functions
### constructor


```solidity
constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) OperatorManager(name_);
```

### _afterStake


```solidity
function _afterStake(address delegator, uint96 amount) internal virtual override;
```

### _afterUnstake


```solidity
function _afterUnstake(address delegator, uint96 amount) internal virtual override;
```

### _afterOperatorSelection


```solidity
function _afterOperatorSelection(address delegator, address operator) internal virtual override;
```

### _afterOperatorUndelegationAnnouncement


```solidity
function _afterOperatorUndelegationAnnouncement(address delegator) internal virtual override;
```

### _afterSlash


```solidity
function _afterSlash(address operator, uint256 remainingPercentage) internal virtual override;
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

*always allow operator to claw back their own token forcefully*


```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override;
```

### _reportOperatorStakeUpdate

*reports the new operator stake to the service contract, triggered by a balance change through a delegator action*

*if requireSuccess is true, the function will revert if the call to the service contract fails*

*if requireSuccess is false, the function will not revert if the call to the service contract fails, this ensures that a delegator cannot be bricked by a malicious operator, they should always be able to undelegate from the operator to withdraw their stake. To ensure an honest undelegation can be processed by the recipient of the call, a minimum amount of gas is enforced.*


```solidity
function _reportOperatorStakeUpdate(address delegator, bool requireSuccess) internal;
```

### _reportOperatorSlash


```solidity
function _reportOperatorSlash(address operator, uint256 remainingPercentage) internal;
```

### _isServiceContract


```solidity
function _isServiceContract(address account) private view returns (bool);
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

