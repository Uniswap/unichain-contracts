# ProtocolRewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/b65aa4f5b827097e05d9ccfdf4601e76462b77b0/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol)

**Inherits:**
[UniStakerWrapper](/src/UVN/L1/StakingMiddleware/UniStakerWrapper.sol/contract.UniStakerWrapper.md), [IProtocolRewardDistributor](/src/interfaces/UVN/L1/StakingMiddleware/IProtocolRewardDistributor.sol/interface.IProtocolRewardDistributor.md)


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
### withdrawRewards


```solidity
function withdrawRewards(address to) public virtual returns (uint256 reward);
```

### rewardsOf


```solidity
function rewardsOf(address account) public view virtual returns (uint256);
```

### _updateGlobalRewardCheckpoint


```solidity
function _updateGlobalRewardCheckpoint() internal returns (uint256 newGlobalRewardCheckpoint);
```

### _updateRewardCheckpoint


```solidity
function _updateRewardCheckpoint(address account) internal;
```

### _getNewGlobalRewardCheckpoint


```solidity
function _getNewGlobalRewardCheckpoint(uint256 reward) internal view returns (uint256);
```

### _calculateRewardUntil


```solidity
function _calculateRewardUntil(address account, uint256 checkpoint) internal view returns (uint256);
```

### _calculateRewardFromTo


```solidity
function _calculateRewardFromTo(uint256 balance, uint256 from, uint256 to) internal pure returns (uint256);
```

