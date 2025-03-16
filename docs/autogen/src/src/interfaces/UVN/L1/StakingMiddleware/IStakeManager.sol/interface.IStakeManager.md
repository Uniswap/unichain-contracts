# IStakeManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/43cfeb46627ac8e6e7739462906618c85350c785/src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol)

**Inherits:**
[IStakingMiddlewareParams](/src/interfaces/UVN/L1/StakingMiddleware/IStakingMiddlewareParams.sol/interface.IStakingMiddlewareParams.md)

This contract is used to manage the stake of a delegator. Delegators can stake the UNI token and withdraw their stake after a delay. After a delegator unstakes, their stake remains slashable until the withdrawal is completed (even if the withdrawal delay has passed but the stake has not been withdrawn yet). Slashings are always applied percentually to the entire stake, including pending withdrawals.


## Functions
### stake

Deposits a stake in the StakingMiddleware contract


```solidity
function stake(uint96 amount) external;
```

### stakeFor

Deposits a stake in the StakingMiddleware contract on behalf of a delegator


```solidity
function stakeFor(address delegator, uint96 amount) external;
```

### unstake

Unstakes a stake from the StakingMiddleware contract and queues it for withdrawal

*The voting power of the delegator is updated to the new stake immediately after unstaking*

*All pending withdrawals are still slashable if delegated to an operator even if the withdrawals are already unlocked!*


```solidity
function unstake(uint96 amount) external returns (uint256 withdrawalId);
```

### withdraw

Withdraws unstaked stakes that are pending to be withdrawn from the StakingMiddleware contract

*If `n` is greater than the number of unlocked pending withdrawals, the function will return early.*


```solidity
function withdraw(address to, uint64 n) external returns (uint96);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to send the unstaked stakes to|
|`n`|`uint64`|The number of pending withdrawals to complete|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint96`|The total amount of unstaked stakes withdrawn|


### delegatorStake

Returns the stake of a delegator deposited in the StakingMiddleware contract


```solidity
function delegatorStake(address delegator) external view returns (uint96);
```

### slashableStake

Returns the slashable stake of a delegator

*The slashable stake is the `delegatorStake` + the total pending withdrawals*


```solidity
function slashableStake(address delegator) external view returns (uint96);
```

### pendingWithdrawalAmount

Returns the amount of pending withdrawals for a delegator


```solidity
function pendingWithdrawalAmount(address delegator) external view returns (uint96);
```

### withdrawal

Returns a withdrawal for a delegator


```solidity
function withdrawal(address delegator, uint256 withdrawalId) external view returns (PendingWithdrawal memory);
```

### STAKE_TOKEN

Returns the stake token


```solidity
function STAKE_TOKEN() external view returns (IERC20);
```

## Events
### Staked
Emitted when a delegator deposits a stake in the StakingMiddleware contract


```solidity
event Staked(address indexed delegator, address indexed sender, uint96 amount);
```

### Unstaked
Emitted when a delegator unstakes a stake from the StakingMiddleware contract


```solidity
event Unstaked(address indexed delegator, uint96 amount, uint40 unlocksAt);
```

### Withdrawn
Emitted when a delegator withdraws unstaked stakes from the StakingMiddleware contract


```solidity
event Withdrawn(address indexed delegator, address indexed recipient, uint96 amount);
```

### PendingWithdrawalsInvalidated
Emitted when a delegator's pending withdrawals are invalidated during slashing


```solidity
event PendingWithdrawalsInvalidated(
    address indexed delegator, uint256 start, uint256 end, uint96 newWithdrawalAmount, uint40 newWithdrawalTimestamp
);
```

### Slashed
Emitted when a delegator's stake is slashed


```solidity
event Slashed(address indexed delegator, uint96 amount, uint96 newStake);
```

## Errors
### InsufficientBalance
Thrown when a user attempts to withdraw more stake than they have deposited


```solidity
error InsufficientBalance();
```

### NoPendingWithdrawalsToWithdraw
Thrown when a user attempts to withdraw stakes that are not yet unlocked

*`nextWithdrawableTimestamp` will be 0 if there are no pending withdrawals*


```solidity
error NoPendingWithdrawalsToWithdraw(uint64 nextWithdrawableTimestamp);
```

## Structs
### PendingWithdrawal

```solidity
struct PendingWithdrawal {
    uint96 amount;
    uint40 timestamp;
    bool withdrawn;
}
```

