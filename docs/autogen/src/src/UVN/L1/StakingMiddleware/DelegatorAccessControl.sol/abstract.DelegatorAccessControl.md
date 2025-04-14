# DelegatorAccessControl
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/UVN/L1/StakingMiddleware/DelegatorAccessControl.sol)

**Inherits:**
[OperatorManager](/src/UVN/L1/StakingMiddleware/OperatorManager.sol/abstract.OperatorManager.md), [IDelegatorAccessControl](/src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol/interface.IDelegatorAccessControl.md)

This contract manages the access control of delegators to operators. It allows Operators to set rules for delegation. Self-delegation is always allowed. Operators can toggle whether delegation to them is allowed or not. Should an operator allow delegation, they can implement their own verification logic by two different mechanisms. Either by providing a verifier contract that implements the `IDelegatorVerifier` interface that verifies whether a delegator is allowed to delegate to them or not. Because the `delegate` function specified by ERC-5805 does not allow for arbitrary data to be passed during delegation, the operator can also provide an `authorizedSender` address. If a delegator is delegating via signature, the `authorizedSender` address can be set to ensure that the signature is provided by a contract that can perform arbitrary checks (e.g., verify a merkle proof to ensure a delegator is allowed).


## State Variables
### _delegatorAccessControl

```solidity
mapping(address delegator => AccessControlParams accessControl) private _delegatorAccessControl;
```


## Functions
### _beforeDelegation

*Before a delegator selects an operator, check if they are allowed to delegate to them*


```solidity
function _beforeDelegation(address delegator, address operator) internal override;
```

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

### _allowDelegation

*Checks if a delegator is allowed to delegate to an operator*

*Self-delegation is always allowed*

*If the operator does not accept delegation, revert*

*If the delegation is via signature and the authorized sender is set, ensure that the `delegate` function is called by the authorized sender*

*If a verifier contract is set, call it to verify if the delegator is allowed to delegate to the operator*

*If the authorized sender is set, but the delegator is not delegating by signature, revert if no verifier is set, else check verifier contract*


```solidity
function _allowDelegation(address delegator, address operator) internal view returns (bool);
```

## Structs
### AccessControlParams

```solidity
struct AccessControlParams {
    bool acceptDelegation;
    address authorizedSender;
    IDelegatorVerifier verifier;
}
```

