# SlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/b65aa4f5b827097e05d9ccfdf4601e76462b77b0/src/UVN/L1/StakingMiddleware/SlashingManager.sol)

**Inherits:**
[ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [OperatorManager](/src/UVN/L1/StakingMiddleware/OperatorManager.sol/abstract.OperatorManager.md)


## State Variables
### PERCENTAGE_DENOMINATOR

```solidity
uint96 private constant PERCENTAGE_DENOMINATOR = 1e18;
```


### _slashingData

```solidity
mapping(address operator => SlashingData data) internal _slashingData;
```


### _delegatorSlashingHead

```solidity
mapping(address delegator => bytes32 operatorTail) internal _delegatorSlashingHead;
```


## Functions
### selectOperator


```solidity
function selectOperator(address operator) public override;
```

### deselectOperator


```solidity
function deselectOperator() public virtual override;
```

### withdrawRewards


```solidity
function withdrawRewards(address to) public override returns (uint256 reward);
```

### slashAmount


```solidity
function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE());
```

### slashPercentage


```solidity
function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE());
```

### applySlashing


```solidity
function applySlashing(address delegator, uint256 n) public;
```

### isDelegatorSlashed


```solidity
function isDelegatorSlashed(address delegator) external view returns (bool);
```

### delegatorStake


```solidity
function delegatorStake(address delegator) public view override returns (uint96);
```

### rewardsOf


```solidity
function rewardsOf(address delegator) public view override returns (uint256);
```

### _slash


```solidity
function _slash(address operator, uint96 remainingPercentage) internal;
```

### _calculateSlashing

*iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.*

*In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.*


```solidity
function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
    internal
    view
    returns (uint96 newStake, bytes32 delegatorHead, uint256 newRewards, uint256 slashedRewards, uint256 newCheckpoint);
```

### _isDelegatorSlashed


```solidity
function _isDelegatorSlashed(bytes32 operatorTail, bytes32 delegatorHead) internal pure returns (bool);
```

### SLASHER_ROLE


```solidity
function SLASHER_ROLE() public view returns (bytes32);
```

## Structs
### SlashingInstance

```solidity
struct SlashingInstance {
    uint96 remainingPercentage;
    uint40 timestamp;
    uint256 rewardCheckpoint;
    bytes32 next;
}
```

### SlashingData

```solidity
struct SlashingData {
    bytes32 head;
    bytes32 tail;
    mapping(bytes32 instanceHash => SlashingInstance instance) instances;
}
```

