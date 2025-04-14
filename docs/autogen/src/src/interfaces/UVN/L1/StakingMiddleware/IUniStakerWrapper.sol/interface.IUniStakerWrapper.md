# IUniStakerWrapper
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/interfaces/UVN/L1/StakingMiddleware/IUniStakerWrapper.sol)

**Inherits:**
[IStakeManager](/src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol/interface.IStakeManager.md)

This contract manages deposits into the UniStaker contract. It allows delegators to participate in UNI governance and accrue protocol fees distributed by the UniStaker contract. The deposit into UniStaker is optional, once a delegator opts in, all subsequent deposits will also be deposited into the UniStaker contract.


## Functions
### depositIntoUniStaker

Deposits the user's underlying stake into the UniStaker contract

*Any subsequent deposits will also be deposited into the UniStaker contract*


```solidity
function depositIntoUniStaker(address governanceDelegatee) external returns (uint256 depositId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`governanceDelegatee`|`address`|The address of the governance delegatee to set|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositId`|`uint256`|The depositId of the deposit identifying the deposit in the UniStaker contract|


### withdrawFromUniStaker

Withdraws all of the user's underlying stake from the UniStaker contract


```solidity
function withdrawFromUniStaker() external;
```

### alterGovernanceDelegatee

Alters the governance delegatee of the user's underlying stake in the UniStaker contract


```solidity
function alterGovernanceDelegatee(address newGovernanceDelegatee) external;
```

### isDepositedIntoUniStaker

Returns whether the user has deposited their underlying stake into the UniStaker contract


```solidity
function isDepositedIntoUniStaker(address delegator) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|The address of the delegator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the user has deposited into the UniStaker contract|


### UNISTAKER

Returns the UniStaker contract


```solidity
function UNISTAKER() external view returns (IUniStaker);
```

### REWARD_TOKEN

Returns the reward token


```solidity
function REWARD_TOKEN() external view returns (IERC20);
```

## Events
### UniStakerDeposited
Emitted when a user deposits into the UniStaker contract


```solidity
event UniStakerDeposited(address indexed delegator, uint256 indexed depositId, uint96 amount);
```

### UniStakerWithdrawn
Emitted when a user withdraws from the UniStaker contract


```solidity
event UniStakerWithdrawn(address indexed delegator, uint256 indexed depositId, uint96 amount);
```

### GovernanceDelegateeAltered
Emitted when a user alters the governance delegatee of their underlying stake in the UniStaker contract


```solidity
event GovernanceDelegateeAltered(address indexed delegator, address newGovernanceDelegatee);
```

## Errors
### AlreadyDepositedIntoUniStaker
Thrown when a user attempts to deposit into the UniStaker contract while already deposited


```solidity
error AlreadyDepositedIntoUniStaker();
```

### NotDepositedIntoUniStaker
Thrown when a user attempts to withdraw from the UniStaker contract while not deposited


```solidity
error NotDepositedIntoUniStaker();
```

### NoStakeToDeposit
Thrown when a user attempts to deposit into the UniStaker contract while not staking any amount


```solidity
error NoStakeToDeposit();
```

