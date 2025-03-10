# IUniStakerWrapper
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/interfaces/UVN/L1/StakingMiddleware/IUniStakerWrapper.sol)

**Inherits:**
[IStakeManager](/src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol/interface.IStakeManager.md)


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

