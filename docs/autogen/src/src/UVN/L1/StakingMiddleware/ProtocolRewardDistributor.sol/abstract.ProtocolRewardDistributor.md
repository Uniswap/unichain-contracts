# ProtocolRewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/729690360d7657f2429fb20679c49eb2f8d71770/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol)

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
### _beforeDeposit


```solidity
function _beforeDeposit(address delegator, uint96 amount) internal virtual override;
```

### _beforeWithdrawal


```solidity
function _beforeWithdrawal(address delegator, uint96 amount) internal virtual override;
```

### _beforeUniStakerDeposit


```solidity
function _beforeUniStakerDeposit(address delegator, uint96 amount) internal virtual override;
```

### _beforeUniStakerWithdrawal


```solidity
function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal virtual override;
```

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

### _distributeRewards


```solidity
function _distributeRewards(address account, uint256 reward, uint256 newCheckpoint) internal;
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

### _beforeRewardsWithdrawal


```solidity
function _beforeRewardsWithdrawal(address delegator) internal virtual;
```

