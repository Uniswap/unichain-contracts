# UniStakerWrapper
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/7dcfc053062e80b4db9d2b818e627cd6f4a79851/src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol)

**Inherits:**
[StakeManager](/src/UVN/L1/StakingMiddleware/StakeManager.sol/contract.StakeManager.md), [IUniStakerWrapper](/src/interfaces/UVN/L1/StakingMiddleware/IUniStakerWrapper.sol/interface.IUniStakerWrapper.md)

This contract manages deposits into the UniStaker contract. It allows delegators to participate in UNI governance and accrue protocol fees distributed by the UniStaker contract. The deposit into UniStaker is optional, once a delegator opts in, all subsequent deposits will also be deposited into the UniStaker contract.


## State Variables
### UNISTAKER
Returns the UniStaker contract


```solidity
IUniStaker public immutable UNISTAKER;
```


### REWARD_TOKEN
Returns the reward token


```solidity
IERC20 public immutable REWARD_TOKEN;
```


### _depositIds

```solidity
mapping(address delegator => uint256 depositId) private _depositIds;
```


## Functions
### constructor


```solidity
constructor(IUniStaker unistaker, address initialAdmin, uint256 withdrawalDelay_, address slashingBeneficiary_)
    StakeManager(address(unistaker.STAKE_TOKEN()), initialAdmin, withdrawalDelay_, slashingBeneficiary_);
```

### _afterStake

*After a delegator stakes, if they are opted into the UniStaker contract, deposit their stake into the UniStaker contract*


```solidity
function _afterStake(address delegator, uint96 amount) internal virtual override;
```

### _beforeWithdraw

*Before a delegator withdraws, if they are opted into the UniStaker contract, withdraw their stake from the UniStaker contract*


```solidity
function _beforeWithdraw(address delegator, uint96 amount) internal virtual override;
```

### _beforeDelegatorSlashed

*Before a delegator is slashed, if they are opted into the UniStaker contract, withdraw their stake from the UniStaker contract*


```solidity
function _beforeDelegatorSlashed(address delegator, uint96 amount, uint96 newStake, uint96 newPendingWithdrawalAmount)
    internal
    virtual
    override;
```

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

### _depositIntoUniStaker

*Deposits a delegator's stake into the UniStaker contract and/or updates their governance delegatee. On first deposit, the delegator MUST provide both, the stake and a delegatee and a deposit id is returned. On subsequent deposits, the deposit id is reused and identifies the delegator's entire stake.*


```solidity
function _depositIntoUniStaker(uint96 amount, address delegatee) internal returns (uint256 depositId);
```

### _withdrawFromUniStaker

*Withdraws an amount from the sender's stake deposited into the UniStaker contract*


```solidity
function _withdrawFromUniStaker(uint96 amount) internal;
```

### _withdrawFromUniStaker

*Withdraws an amount from a delegator's stake deposited into the UniStaker contract. If the entire stake is withdrawn, subsequent deposits will no longer auto-deposit into the UniStaker contract.*


```solidity
function _withdrawFromUniStaker(address delegator, uint96 amount) internal;
```

### _stakedBalanceOf


```solidity
function _stakedBalanceOf(address delegator) internal view returns (uint96);
```

### _totalAmountDepositedIntoUniStaker


```solidity
function _totalAmountDepositedIntoUniStaker() internal view returns (uint96);
```

### _isDepositedIntoUniStaker


```solidity
function _isDepositedIntoUniStaker(address delegator) internal view returns (bool);
```

### _beforeUniStakerDeposit


```solidity
function _beforeUniStakerDeposit(address delegator) internal virtual;
```

### _beforeUniStakerWithdrawal


```solidity
function _beforeUniStakerWithdrawal(address delegator) internal virtual;
```

### _beforeUniStakerDelegateChange


```solidity
function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal virtual;
```

