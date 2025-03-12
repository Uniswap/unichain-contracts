# DelegatorAccessControl
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/07d4bd0c93642e180d59fb2de755cf59c8c044e6/src/UVN/L1/StakingMiddleware/DelegatorAccessControl.sol)

**Inherits:**
[IDelegatorAccessControl](/src/interfaces/UVN/L1/StakingMiddleware/IDelegatorAccessControl.sol/interface.IDelegatorAccessControl.md), [OperatorManager](/src/UVN/L1/StakingMiddleware/OperatorManager.sol/abstract.OperatorManager.md)


## State Variables
### _delegatorAccessControl

```solidity
mapping(address delegator => AccessControl accessControl) private _delegatorAccessControl;
```


## Functions
### _beforeOperatorSelection


```solidity
function _beforeOperatorSelection(address delegator, address operator) internal override;
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

### _allowDelegation


```solidity
function _allowDelegation(address delegator, address operator) internal view returns (bool);
```

## Structs
### AccessControl

```solidity
struct AccessControl {
    bool acceptDelegation;
    address authorizedSender;
    IDelegatorVerifier verifier;
}
```

