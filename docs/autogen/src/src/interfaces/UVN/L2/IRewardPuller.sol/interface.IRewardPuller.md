# IRewardPuller
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/interfaces/UVN/L2/IRewardPuller.sol)

**Inherits:**
IERC165

Contracts implementing this interface can be called by the reward distributor automatically to pull new rewards.


## Functions
### pullRewards

Pulls rewards from a reward source in ETH and forwards them to the reward distributor contract


```solidity
function pullRewards() external returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of rewards pulled|


