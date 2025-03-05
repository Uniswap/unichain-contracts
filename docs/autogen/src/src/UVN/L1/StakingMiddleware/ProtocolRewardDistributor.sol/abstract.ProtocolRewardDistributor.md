# ProtocolRewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/dbd11eeb90f59abe0099dfbb1022b6093132bf21/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol)

**Inherits:**
[UniStakerWrapper](/src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol/contract.UniStakerWrapper.md), [IProtocolRewardDistributor](/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol/interface.IProtocolRewardDistributor.md)


## State Variables
### PRECISION

```solidity
uint256 private constant PRECISION = 1e27;
```


### _globalRewardCheckpoint

```solidity
uint256 private _globalRewardCheckpoint;
```


### _rewardCheckpointOf

```solidity
mapping(address account => uint256 checkpoint) private _rewardCheckpointOf;
```


### _earnedRewardsOf

```solidity
mapping(address account => uint256 earnedRewards) private _earnedRewardsOf;
```


## Functions
### withdrawRewards


```solidity
function withdrawRewards(address to) external returns (uint256 reward);
```

### rewardsOf


```solidity
function rewardsOf(address account) public view returns (uint256);
```

### _updateRewardIndex


```solidity
function _updateRewardIndex() internal;
```

### _updateRewardCheckpoint


```solidity
function _updateRewardCheckpoint(address account) internal;
```

### _calculateRewardSinceLastCheckpoint


```solidity
function _calculateRewardSinceLastCheckpoint(address account) internal view returns (uint256);
```

