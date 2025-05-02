# StakeManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/d36fee7571a3aee70804ae50127a8ca3e2e6fc63/src/UVN/L1/StakingMiddleware/StakeManager.sol)

**Inherits:**
[StakingMiddlewareParams](/src/UVN/L1/StakingMiddleware/StakingMiddlewareParams.sol/contract.StakingMiddlewareParams.md), [IStakeManager](/src/interfaces/UVN/L1/StakingMiddleware/IStakeManager.sol/interface.IStakeManager.md)

This contract is used to manage the stake of a delegator. Delegators can stake the UNI token and withdraw their stake after a delay. After a delegator unstakes, their stake remains slashable until the withdrawal is completed (even if the withdrawal delay has passed but the stake has not been withdrawn yet). Slashings are always applied percentually to the entire stake, including pending withdrawals.


## State Variables
### PERCENTAGE_DENOMINATOR

```solidity
uint256 internal constant PERCENTAGE_DENOMINATOR = 1e18;
```


### _depositorStake

```solidity
mapping(address delegator => Stake stake) private _depositorStake;
```


### STAKE_TOKEN

```solidity
IERC20 public immutable STAKE_TOKEN;
```


## Functions
### constructor


```solidity
constructor(address stakeToken, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    StakingMiddlewareParams(initialAdmin, withdrawalDelay_, slashingBeneficiary_);
```

### stake

Deposits a stake in the StakingMiddleware contract


```solidity
function stake(uint96 amount) external;
```

### stakeFor

Deposits a stake in the StakingMiddleware contract on behalf of a delegator


```solidity
function stakeFor(address delegator, uint96 amount) public;
```

### unstake

Unstakes a stake from the StakingMiddleware contract and queues it for withdrawal

*The voting power of the delegator is updated to the new stake immediately after unstaking*


```solidity
function unstake(uint96 amount) external returns (uint256 withdrawalId);
```

### withdraw

Withdraws unstaked stakes that are pending to be withdrawn from the StakingMiddleware contract

*If `n` is greater than the number of unlocked pending withdrawals, the function will return early.*


```solidity
function withdraw(address to, uint64 n) external returns (uint96 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to send the unstaked stakes to|
|`n`|`uint64`|The number of pending withdrawals to complete|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint96`|The total amount of unstaked stakes withdrawn|


### delegatorStake

Returns the stake of a delegator deposited in the StakingMiddleware contract


```solidity
function delegatorStake(address delegator) public view virtual returns (uint96);
```

### slashableStake

Returns the slashable stake of a delegator

*The slashable stake is the `delegatorStake` + the total pending withdrawals*


```solidity
function slashableStake(address delegator) public view virtual returns (uint96);
```

### pendingWithdrawalAmount

Returns the amount of pending withdrawals for a delegator


```solidity
function pendingWithdrawalAmount(address delegator) public view virtual returns (uint96);
```

### withdrawal

Returns a withdrawal for a delegator


```solidity
function withdrawal(address delegator, uint256 withdrawalId)
    external
    view
    returns (IStakeManager.PendingWithdrawal memory);
```

### _slashDelegatorStake

*To ensure accurate accounting of total delegated stake to operators, pending withdrawals and slashable stake are slashed equally*

*When pending withdrawals are slashed, cancel all pending withdrawals and create a new one with the remainder*


```solidity
function _slashDelegatorStake(address delegator, uint96 newStake, uint96 newPendingWithdrawalAmount) internal;
```

### _schedulePendingWithdrawal


```solidity
function _schedulePendingWithdrawal(address delegator, uint96 amount) internal virtual returns (uint256 withdrawalId);
```

### _invalidatePendingWithdrawals


```solidity
function _invalidatePendingWithdrawals(address delegator) private;
```

### _delegatorStake


```solidity
function _delegatorStake(address delegator) internal view virtual returns (uint96);
```

### _slashableStake

*slashable stake is the sum of the stake and the total pending withdrawals*


```solidity
function _slashableStake(address delegator) internal view virtual returns (uint96);
```

### _beforeStake


```solidity
function _beforeStake(address delegator, uint96 amount) internal virtual;
```

### _afterStake


```solidity
function _afterStake(address delegator, uint96 amount) internal virtual;
```

### _beforeUnstake


```solidity
function _beforeUnstake(address delegator, uint96 amount) internal virtual;
```

### _afterUnstake


```solidity
function _afterUnstake(address delegator, uint96 amount) internal virtual;
```

### _beforeWithdrawCalculation


```solidity
function _beforeWithdrawCalculation(address delegator) internal virtual;
```

### _beforeWithdraw


```solidity
function _beforeWithdraw(address delegator, uint96 amount) internal virtual;
```

### _afterWithdraw


```solidity
function _afterWithdraw(address delegator, uint96 amount) internal virtual;
```

### _beforeDelegatorSlashed


```solidity
function _beforeDelegatorSlashed(address delegator, uint96 amount, uint96 newStake, uint96 newPendingWithdrawalAmount)
    internal
    virtual;
```

### _afterDelegatorSlashed


```solidity
function _afterDelegatorSlashed(address delegator, uint96 amount, uint96 newStake, uint96 newPendingWithdrawalAmount)
    internal
    virtual;
```

## Structs
### Stake

```solidity
struct Stake {
    uint96 stake;
    uint96 totalPendingWithdrawal;
    uint64 head;
    IStakeManager.PendingWithdrawal[] pendingWithdrawals;
}
```

