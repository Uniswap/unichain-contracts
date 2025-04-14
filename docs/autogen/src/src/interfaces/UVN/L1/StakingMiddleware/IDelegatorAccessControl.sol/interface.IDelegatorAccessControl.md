# IDelegatorAccessControl
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/43cfeb46627ac8e6e7739462906618c85350c785/src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol)

**Inherits:**
[IOperatorManager](/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol/interface.IOperatorManager.md)

This contract manages the access control of delegators to operators. It allows Operators to set rules for delegation. Self-delegation is always allowed. Operators can toggle whether delegation to them is allowed or not. Should an operator allow delegation, they can implement their own verification logic by two different mechanisms. Either by providing a verifier contract that implements the `IDelegatorVerifier` interface that verifies whether a delegator is allowed to delegate to them or not. Because the `delegate` function specified by ERC-5805 does not allow for arbitrary data to be passed during delegation, the operator can also provide an `authorizedSender` address. If a delegator is delegating via signature, the `authorizedSender` address can be set to ensure that the signature is provided by a contract that can perform arbitrary checks (e.g., verify a merkle proof to ensure a delegator is allowed).


## Functions
### setDelegationStatus

Enables or disables delegation to the operator

*When enabled, it starts enforcing the delegation verifier and authorized sender*


```solidity
function setDelegationStatus(bool status) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`status`|`bool`|The new delegation status|


### setDelegationVerifier

Sets a delegation verifier contract

*when delegating by signature and an authorized sender is not set, the verifier delegation verifier is enforced*


```solidity
function setDelegationVerifier(IDelegatorVerifier verifier) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`verifier`|`IDelegatorVerifier`|The address of the delegation verifier contract|


### setAuthorizedSender

Sets the authorized sender


```solidity
function setAuthorizedSender(address sender) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`address`|The address of the authorized sender|


### delegationStatus

Returns the delegation status


```solidity
function delegationStatus(address operator) external view returns (bool);
```

### delegationVerifier

Returns the delegation verifier


```solidity
function delegationVerifier(address operator) external view returns (IDelegatorVerifier);
```

### authorizedSender

Returns the authorized sender


```solidity
function authorizedSender(address operator) external view returns (address);
```

## Events
### DelegationStatusUpdated
Emitted when the delegation status is set


```solidity
event DelegationStatusUpdated(address indexed operator, bool status);
```

### DelegationVerifierUpdated
Emitted when the delegation verifier is set


```solidity
event DelegationVerifierUpdated(address indexed operator, IDelegatorVerifier verifier);
```

### AuthorizedSenderUpdated
Emitted when the authorized sender is set


```solidity
event AuthorizedSenderUpdated(address indexed operator, address sender);
```

## Errors
### DelegationDisallowed
Thrown when a delegator attempts to delegate to an operator while not meeting criteria set by the operator


```solidity
error DelegationDisallowed();
```

