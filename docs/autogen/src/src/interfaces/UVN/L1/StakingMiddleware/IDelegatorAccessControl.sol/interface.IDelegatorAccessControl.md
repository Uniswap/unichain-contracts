# IDelegatorAccessControl
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/07d4bd0c93642e180d59fb2de755cf59c8c044e6/src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol)

**Inherits:**
[IOperatorManager](/src/interfaces/UVN/L1/StakingMiddleware/IOperatorManager.sol/interface.IOperatorManager.md)


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

*when delegating by signature and the authorized sender is set, the verifier contract is not called, as the delegation already passed an authorization check*


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

