# SlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/7f66025a53e574ca519390c88a9335515138fc79/src/UVN/L1/StakingMiddleware/SlashingManager.sol)

**Inherits:**
[DelegatorAccessControl](/src/UVN/L1/StakingMiddleware/DelegatorAccessControl.sol/abstract.DelegatorAccessControl.md), [ISlashingManager](/src/interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol/interface.ISlashingManager.md)

This contract manages the slashing of delegators and operators. When operators are slashed, the slashed amount is converted into the remaining percentage of the operator's slashable delegated stake. The voting power of the operator is updated immediately. As delegators have their own deposits into the UniStaker contract, slashing is applied to the delegator's slashable stake when the delegator next interacts with the StakingMiddleware contract. Slashing can also be applied by anyone at any time. To ensure there isn't an incentive to not stay slashed and continue accruing protocol fees in the UniStaker contract, rewards accrued by the delegator are also slashed.


## State Variables
### SLASHER_ROLE

```solidity
bytes32 public constant SLASHER_ROLE = keccak256('SLASHER_ROLE');
```


### _slashingInstances
*List of slashing instances for an operator*


```solidity
mapping(address operator => SlashingInstance[] instances) internal _slashingInstances;
```


### _delegatorNextSlashingInstance
*Points to the next slashing instance of an operator a delegator delegated to, if the next slashing instance is equal to the operator's slashing instances array length, the delegator is not slashed*


```solidity
mapping(address delegator => uint256 nextSlashingInstance) internal _delegatorNextSlashingInstance;
```


## Functions
### _afterDelegation

*After a delegator selects an operator, store the number of slashing instances an operator had before the delegation to keep track of future slashing instances that occur after the delegation*


```solidity
function _afterDelegation(address delegator, address operator) internal virtual override;
```

### _afterUndelegation

*After a delegator undelegates from an operator, reset the slashing tracking data for the delegator*


```solidity
function _afterUndelegation(address delegator) internal virtual override;
```

### _beforeStake

*Before a delegator stakes, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeStake(address delegator, uint96 amount) internal override;
```

### _beforeUnstake

*Before a delegator unstakes, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeUnstake(address delegator, uint96 amount) internal override;
```

### _beforeWithdrawCalculation

*Before a delegator withdraws, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeWithdrawCalculation(address delegator) internal override;
```

### _beforeUniStakerDeposit

*Before a delegator deposits into the UniStaker contract, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeUniStakerDeposit(address delegator) internal override;
```

### _beforeUniStakerWithdrawal

*Before a delegator withdraws from the UniStaker contract, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeUniStakerWithdrawal(address delegator) internal override;
```

### _beforeUniStakerDelegateChange

*Before a delegator changes their governance delegatee, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal override;
```

### _beforeRewardsWithdrawal

*Before a delegator withdraws their rewards, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeRewardsWithdrawal(address delegator) internal override;
```

### _beforeUndelegationAnnouncement

*Before a delegator announces their intention to undelegate from an operator, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeUndelegationAnnouncement(address delegator) internal override;
```

### _beforeUndelegation

*Before a delegator undelegates from an operator, apply all pending slashing instances to the delegator's stake*


```solidity
function _beforeUndelegation(address delegator) internal override;
```

### slashAmount

Slashes a delegator's stake by a specific amount


```solidity
function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE);
```

### slashPercentage

Slashes a delegator's stake by a percentage of the total stake


```solidity
function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE);
```

### applySlashing

Applies pending slashing to a delegator's stake


```solidity
function applySlashing(address delegator, uint256 n) public;
```

### slashingPendingForDelegator

Returns whether a delegator's stake is slashed and is pending for finalization


```solidity
function slashingPendingForDelegator(address delegator) external view returns (bool);
```

### rewardsOf

*Overrides the `rewardsOf` function in `ProtocolRewardDistributor` to reflect correct rewards for a delegator accounting for slashing*


```solidity
function rewardsOf(address delegator)
    public
    view
    override(ProtocolRewardDistributor, IProtocolRewardDistributor)
    returns (uint256);
```

### _slashOperatorVotes


```solidity
function _slashOperatorVotes(address operator, uint256 remainingPercentage) internal override;
```

### delegatorStake

*Overrides the `delegatorStake` function in `StakeManager` to reflect correct stake for a delegator accounting for slashing*


```solidity
function delegatorStake(address delegator) public view override(StakeManager, IStakeManager) returns (uint96);
```

### slashableStake

*Overrides the `slashableStake` function in `StakeManager` to reflect correct slashable stake for a delegator accounting for slashing*


```solidity
function slashableStake(address delegator) public view override(StakeManager, IStakeManager) returns (uint96);
```

### _calculateSlashing

*iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.*

*In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.*


```solidity
function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
    internal
    view
    returns (SlashingResult memory result);
```

### _isDelegatorSlashed

*Checks whether a delegator has pending slashing instances, if the next slashing instance is equal to the operator's slashing instances array length, the delegator is not slashed*


```solidity
function _isDelegatorSlashed(uint256 nextDelegatorInstance, uint256 operatorLength) internal pure returns (bool);
```

### _remainingStake

*Applies a slashing result to a stake*


```solidity
function _remainingStake(uint96 stake_, SlashingResult memory result) internal pure returns (uint96);
```

### _slashingOccurred

*Checks a slashing result whether a slashing occurred, if the remaining percentage is not 100%, a slashing occurred*


```solidity
function _slashingOccurred(SlashingResult memory result) internal pure returns (bool);
```

### _afterSlash


```solidity
function _afterSlash(address operator, uint256 remainingPercentage) internal virtual;
```

### _afterDelegatorSlash


```solidity
function _afterDelegatorSlash(address delegator) internal virtual;
```

## Structs
### SlashingInstance
*Slashing instance recorded when an operator is slashed*


```solidity
struct SlashingInstance {
    uint96 remainingPercentage;
    uint256 rewardCheckpoint;
}
```

### SlashingResult
*Result of a slashing calculation*


```solidity
struct SlashingResult {
    uint256 remainingPercentage;
    uint256 next;
    uint256 newRewards;
    uint256 slashedRewards;
    uint256 newCheckpoint;
}
```

