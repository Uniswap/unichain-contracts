# Notifier
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/31f7d1e84e305ebb14dd3f50a3450497938c6404/src/UVN/L1/StakingMiddleware/Notifier.sol)

**Inherits:**
[SlashingManager](/src/UVN/L1/StakingMiddleware/SlashingManager.sol/abstract.SlashingManager.md), ERC721, [INotifier](/src/interfaces/UVN/L1/StakingMiddleware/INotifier.sol/interface.INotifier.md)

This contract allows operators to mint ERC721 tokens to deposit into service contracts they want to operate for. Whenever a delegator modifies their stake or the operator is slashed, the current owner of the token is notified (e.g., service contract). This allows the operator to participate in network upgrades by depositing their token into a new service contract. Additionally, it allows service contracts to implement arbitrary logic on deposits by requiring data to be sent alongside the token, implement their own migration logic, etc. Additionally, the operator can set a URI for their token where they can expose an endpoint to provide more information about themselves.


## State Variables
### TRUSTED_SERVICE_ROLE
Trusted service role

*If a service contract is marked as trusted, reverts on slashings and on undelegations will revert the parent call.*


```solidity
bytes32 public constant TRUSTED_SERVICE_ROLE = keccak256('TRUSTED_SERVICE_ROLE');
```


### MIN_GAS

```solidity
uint256 private constant MIN_GAS = 500_000;
```


### SERVICE_CHECK_GAS

```solidity
uint256 private constant SERVICE_CHECK_GAS = 10_000;
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

*Report the new operator stake after staking*

*Failing call to service contract can prevent a delegator from staking*


```solidity
function _afterStake(address delegator, uint96 amount) internal virtual override;
```

### _afterUnstake

*Report the new operator stake after unstaking*

*Failing call to service contract can prevent a delegator from unstaking*

*Should a malicious service contract prevent unstaking, the delegator can always undelegate from the operator first*


```solidity
function _afterUnstake(address delegator, uint96 amount) internal virtual override;
```

### _afterDelegation

*Report the new operator stake after delegation*

*Failing call to service contract can prevent a delegator from delegating to an operator*


```solidity
function _afterDelegation(address delegator, address operator) internal virtual override;
```

### _afterUndelegationAnnouncement

*Report the new operator stake after undelegation announcement*

*Set delegator stake to 0 as the delegator is undelegating their entire stake*

*Call to service contract is not required to prevent a DOS attack on delegators*


```solidity
function _afterUndelegationAnnouncement(address delegator) internal virtual override;
```

### _afterSlash

*Report the operator slash to the service contract*

*Ensures the service contract cannot prevent the operator from being slashed by reverting the call*


```solidity
function _afterSlash(address operator, uint256 remainingPercentage) internal virtual override;
```

### _afterDelegatorSlash

*After slashing is applied, report the new delegator stake to the service contract*


```solidity
function _afterDelegatorSlash(address delegator) internal virtual override;
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

*Only allow transfers to service contracts and the operator*

*Notify service contracts of withdrawals*


```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override;
```

### _reportOperatorStakeUpdate

*Reports the new operator stake to the service contract, triggered by a balance change through a delegator action*

*If requireSuccess is true, the function will revert if the call to the service contract fails*

*If requireSuccess is false, the function will not revert if the call to the service contract fails, this ensures that a delegator cannot be DOSed by a malicious operator, they should always be able to undelegate from the operator to withdraw their stake. To ensure an honest undelegation can be processed by the recipient of the call, a minimum amount of gas is enforced.*


```solidity
function _reportOperatorStakeUpdate(
    address operator,
    uint96 operatorStake,
    address delegator,
    uint96 delegatorStake_,
    bool requireSuccess
) internal;
```

### _reportOperatorSlash

*Reports the operator slash to the service contract*

*Ensures the service contract cannot prevent the operator from being slashed by reverting the call*


```solidity
function _reportOperatorSlash(address operator, uint256 remainingPercentage) internal;
```

### _isAuthorized

*Allow the operator to always force transfer their own token*


```solidity
function _isAuthorized(address owner, address spender, uint256 tokenId) internal view override returns (bool);
```

### _isServiceContract

*Checks if an account is a service contract by ensuring that the account is not an EOA or 7702 enabled account and that the smart contract supports the `IService` interface*

*Prevents malicious service contracts from preventing force transfers by reverting the ERC-165 check*


```solidity
function _isServiceContract(address account) internal view returns (bool);
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool);
```

