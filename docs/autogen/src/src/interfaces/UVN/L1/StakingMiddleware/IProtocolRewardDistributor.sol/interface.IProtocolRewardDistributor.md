# IProtocolRewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/43cfeb46627ac8e6e7739462906618c85350c785/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol)

**Inherits:**
[IUniStakerWrapper](/src/interfaces/UVN/L1/StakingMiddleware/IUniStakerWrapper.sol/interface.IUniStakerWrapper.md)

This contract distributes accrued protocol fees to delegators that have opted into depositing their underlying UNI stake into the UniStaker contract.


## Functions
### withdrawRewards

Withdraws the user's protocol rewards


```solidity
function withdrawRewards(address to) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to send the rewards to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of protocol rewards withdrawn|


### rewardsOf

Returns the amount of protocol rewards a user has earned


```solidity
function rewardsOf(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the user to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of protocol rewards the user has earned|


## Events
### RewardsAdded
Emitted when protocol rewards are added from the UniStaker contract


```solidity
event RewardsAdded(uint256 amount);
```

### RewardDistributed
Emitted when a user's rewards are distributed


```solidity
event RewardDistributed(address indexed account, uint256 amount);
```

### RewardsWithdrawn
Emitted when a user withdraws their rewards


```solidity
event RewardsWithdrawn(address indexed account, address indexed to, uint256 amount);
```

