# SlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/10fd24e97f437a5e7731628f80c2a61f2eb81fe3/src/UVN/L1/StakingMiddleware/SlashingManager.sol)

**Inherits:**
[DelegatorAccessControl](/src/UVN/L1/StakingMiddleware/DelegatorAccessControl.sol/abstract.DelegatorAccessControl.md), [ISlashingManager](/src/interfaces/UVN/L1/StakingMiddleware/ISlashingManager.sol/interface.ISlashingManager.md)


## State Variables
### _slashingInstances

```solidity
mapping(address operator => SlashingInstance[] instances) internal _slashingInstances;
```


### _delegatorSlashingData

```solidity
mapping(address delegator => DelegatorSlashingData data) internal _delegatorSlashingData;
```


## Functions
### _afterOperatorSelection


```solidity
function _afterOperatorSelection(address delegator, address operator) internal virtual override;
```

### _afterOperatorDeselection


```solidity
function _afterOperatorDeselection(address delegator) internal virtual override;
```

### _beforeStake


```solidity
function _beforeStake(address delegator, uint96 amount) internal override;
```

### _beforeUnstake


```solidity
function _beforeUnstake(address delegator, uint96 amount) internal override;
```

### _beforeWithdraw


```solidity
function _beforeWithdraw(address delegator, uint96 amount) internal override;
```

### _beforeUniStakerDeposit


```solidity
function _beforeUniStakerDeposit(address delegator, uint96 amount) internal override;
```

### _beforeUniStakerWithdrawal


```solidity
function _beforeUniStakerWithdrawal(address delegator, uint96 amount) internal override;
```

### _beforeUniStakerDelegateChange


```solidity
function _beforeUniStakerDelegateChange(address delegator, address newGovernanceDelegatee) internal override;
```

### _beforeRewardsWithdrawal


```solidity
function _beforeRewardsWithdrawal(address delegator) internal override;
```

### _beforeOperatorUndelegationAnnouncement


```solidity
function _beforeOperatorUndelegationAnnouncement(address delegator) internal override;
```

### _beforeOperatorDeselection


```solidity
function _beforeOperatorDeselection(address delegator) internal override;
```

### slashAmount

Slashes a delegator's stake by a specific amount


```solidity
function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE());
```

### slashPercentage

Slashes a delegator's stake by a percentage of the total stake


```solidity
function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE());
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

### _delegatorStake


```solidity
function _delegatorStake(address delegator) internal view override returns (uint96);
```

### _slashableStake


```solidity
function _slashableStake(address delegator) internal view override returns (uint96);
```

### _calculateSlashing

*iterates over slashing occurrences by the operator a delegator has selected. For every slashing instance, it calculates the new stake based on the total percentage of the total delegated stake slashed.*

*In case a delegator has deposited their tokens into UniStaker, to ensure they do not accrue rewards for slashed stake, rewards are also adjusted by the slashed amount. As the slashed stake remains in the UniStaker contract until slashing is applied, the slashed stake is treated as a deposit by the slashing beneficiary, meaning the slashing beneficiary accrues the rewards for the slashed stake instead of the delegator until slashing is applied and the underlying stake is withdrawn.*


```solidity
function _calculateSlashing(address delegator, uint256 n, uint256 globalCheckpoint)
    internal
    view
    returns (
        SlashingType slashingType,
        uint256 remainingPercentage,
        uint160 delegatorLength,
        uint256 newRewards,
        uint256 slashedRewards,
        uint256 newCheckpoint
    );
```

### _isDelegatorSlashed


```solidity
function _isDelegatorSlashed(uint256 delegatorInstanceLength, uint256 operatorLength) internal pure returns (bool);
```

### _remainingStake


```solidity
function _remainingStake(uint96 stake_, uint256 remainingPercentage) internal pure returns (uint96);
```

### SLASHER_ROLE

TODO invalidation of group of slashers?


```solidity
function SLASHER_ROLE() public pure returns (bytes32);
```

## Structs
### SlashingInstance

```solidity
struct SlashingInstance {
    uint96 remainingPercentage;
    uint256 rewardCheckpoint;
}
```

### DelegatorSlashingData

```solidity
struct DelegatorSlashingData {
    uint160 length;
    uint96 stakeBeforePartialSlashing;
}
```

## Enums
### SlashingType

```solidity
enum SlashingType {
    NOT_SLASHED,
    PARTIAL_SLASH,
    FULL_SLASH
}
```

