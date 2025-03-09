# SlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/8410d8a26ef6768cace9d9639c7335103ec75181/src/UVN/L1/StakingMiddleware/SlashingManager.sol)

**Inherits:**
[ProtocolRewardDistributor](/src/UVN/L1/StakingMiddleware/ProtocolRewardDistributor.sol/abstract.ProtocolRewardDistributor.md), [OperatorManager](/src/UVN/L1/StakingMiddleware/OperatorManager.sol/abstract.OperatorManager.md)


## State Variables
### PERCENTAGE_DENOMINATOR

```solidity
uint96 private constant PERCENTAGE_DENOMINATOR = 1e18;
```


### _slashingInstances

```solidity
mapping(address operator => SlashingInstance[] instances) internal _slashingInstances;
```


### _delegatorInstanceLengths

```solidity
mapping(address delegator => uint256 instanceLength) internal _delegatorInstanceLengths;
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
    returns (
        uint96 newStake,
        uint256 delegatorLength,
        uint256 newRewards,
        uint256 slashedRewards,
        uint256 newCheckpoint
    );
```

### _isDelegatorSlashed


```solidity
function _isDelegatorSlashed(uint256 delegatorInstanceLength, uint256 operatorLength) internal pure returns (bool);
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
    uint256 rewardCheckpoint;
}
```

