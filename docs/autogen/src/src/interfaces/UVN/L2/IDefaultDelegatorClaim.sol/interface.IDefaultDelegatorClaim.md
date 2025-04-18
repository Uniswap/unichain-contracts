# IDefaultDelegatorClaim
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/31f7d1e84e305ebb14dd3f50a3450497938c6404/src/interfaces/UVN/L2/IDefaultDelegatorClaim.sol)

**Inherits:**
[IDelegatorClaim](/src/interfaces/UVN/L2/IDelegatorClaim.sol/interface.IDelegatorClaim.md), [IERC7751](/src/interfaces/IERC7751.sol/interface.IERC7751.md)

This contract distributes rewards sent to it by the reward distributor contract. Additionally the contract allows an operator to define arbitrary logic on how to handle their fees.


## Functions
### setOperatorFeeManager

Sets the operator fee manager

*Only the operator can set the operator fee manager*


```solidity
function setOperatorFeeManager(IOperatorFeeManager operatorFeeManager) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operatorFeeManager`|`IOperatorFeeManager`|The address of the operator fee manager|


### claimRewards

Allows a delegator to claim their rewards

*The caller must be the delegator or an aliased address of the delegator from L1*

*When implementing a contract on L1 that acts as a delegator make sure that a contract that can call this function cannot be deployed on L2 by a 3rd party as this would allow them to claim rewards for the delegator.*


```solidity
function claimRewards(address delegator, address to) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|The address of the delegator|
|`to`|`address`|The address to send the rewards to|


### rewardsOf

Returns the rewards of a delegator


```solidity
function rewardsOf(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the delegator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The rewards of the delegator|


### operatorFeeManager

Returns the operator fee manager


```solidity
function operatorFeeManager() external view returns (IOperatorFeeManager);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IOperatorFeeManager`|The operator fee manager|


### totalDelegation

Returns the total amount delegated to an operator


```solidity
function totalDelegation() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total delegated amount|


### delegationOf

Returns the amount delegated to an operator by a delegator


```solidity
function delegationOf(address delegator) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|The address of the delegator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The delegation of the delegator|


### OPERATOR

Returns the operator


```solidity
function OPERATOR() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The operator|


## Events
### BalanceUpdated
Emitted when the balance of a delegator changes


```solidity
event BalanceUpdated(address indexed delegator, uint256 newBalance);
```

### RewardDistributed
Emitted when rewards are distributed to delegators and the operator fee is taken


```solidity
event RewardDistributed(uint256 delegatorReward, uint256 operatorFee);
```

### OperatorFeeManagerSet
Emitted when the operator fee manager is set


```solidity
event OperatorFeeManagerSet(address newOperatorFeeManager);
```

### RewardsClaimed
Emitted when rewards are claimed by a delegator


```solidity
event RewardsClaimed(address indexed delegator, address indexed to, uint256 amount);
```

## Errors
### NotStakeTable
Thrown when the caller is not the stake table


```solidity
error NotStakeTable();
```

### EthTransferFailed
Thrown when the ETH transfer fails


```solidity
error EthTransferFailed();
```

### NoDelegations
Thrown when there are no delegations when distributing rewards


```solidity
error NoDelegations();
```

### OperatorFeeExceedsReward
Thrown when the operator fee exceeds the reward


```solidity
error OperatorFeeExceedsReward();
```

### NotOperator
Thrown when the caller is not the operator


```solidity
error NotOperator();
```

### NotDelegator
Thrown when the caller is not the delegator or an aliased address of the delegator from L1


```solidity
error NotDelegator();
```

