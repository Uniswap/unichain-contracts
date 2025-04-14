# ProtocolRewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol)

**Inherits:**
[UniStakerWrapper](/src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol/contract.UniStakerWrapper.md), [IProtocolRewardDistributor](/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol/interface.IProtocolRewardDistributor.md)

This contract distributes accrued protocol fees to delegators that have opted into depositing their underlying UNI stake into the UniStaker contract.


## State Variables
### PRECISION

```solidity
uint256 private constant PRECISION = 1e27;
```


### _globalRewardCheckpoint

```solidity
uint256 internal _globalRewardCheckpoint;
```


### _rewardCheckpointOf

```solidity
mapping(address account => uint256 checkpoint) internal _rewardCheckpointOf;
```


### _earnedRewardsOf

```solidity
mapping(address account => uint256 earnedRewards) internal _earnedRewardsOf;
```


## Functions
### _beforeStake

*before a delegator stakes, claim rewards with the balance prior to the deposit*


```solidity
function _beforeStake(address delegator, uint96 amount) internal virtual override;
```

### _beforeWithdraw

*before a delegator withdraws, claim rewards with the balance prior to the withdrawal*


```solidity
function _beforeWithdraw(address delegator, uint96 amount) internal virtual override;
```

### _beforeUniStakerDeposit

*before a delegator deposits into the UniStaker contract, update their checkpoint to ensure correct reward distribution*


```solidity
function _beforeUniStakerDeposit(address delegator) internal virtual override;
```

### _beforeUniStakerWithdrawal

*before a delegator withdraws from the UniStaker contract, claim rewards with the balance prior to the withdrawal*


```solidity
function _beforeUniStakerWithdrawal(address delegator) internal virtual override;
```

### withdrawRewards

Withdraws the user's protocol rewards


```solidity
function withdrawRewards(address to) public virtual returns (uint256 reward);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to send the rewards to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`uint256`|The amount of protocol rewards withdrawn|


### rewardsOf

Returns the amount of protocol rewards a user has earned


```solidity
function rewardsOf(address account) public view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the user to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of protocol rewards the user has earned|


### _updateGlobalRewardCheckpoint

*claims rewards from the UniStaker contract for all delegators*


```solidity
function _updateGlobalRewardCheckpoint() internal returns (uint256 newGlobalRewardCheckpoint);
```

### _updateRewardCheckpoint

*Pulls rewards from the UniStaker contracts and distributes them across all delegators, then updates the reward checkpoint for the delegator*


```solidity
function _updateRewardCheckpoint(address account) internal;
```

### _distributeRewards

*Distributes rewards to a delegator and updates their reward checkpoint*


```solidity
function _distributeRewards(address account, uint256 reward, uint256 newCheckpoint) internal;
```

### _getNewGlobalRewardCheckpoint

*Calculates the new global reward checkpoint based on a new reward amount*


```solidity
function _getNewGlobalRewardCheckpoint(uint256 reward) internal view returns (uint256);
```

### _calculateRewardUntil

*Calculates the rewards a delegator has earned up to a given checkpoint*


```solidity
function _calculateRewardUntil(address account, uint256 checkpoint) internal view returns (uint256);
```

### _calculateRewardFromTo

*Calculates the rewards a balance earns between two checkpoints*


```solidity
function _calculateRewardFromTo(uint256 balance, uint256 from, uint256 to) internal pure returns (uint256);
```

### _beforeRewardsWithdrawal


```solidity
function _beforeRewardsWithdrawal(address delegator) internal virtual;
```

