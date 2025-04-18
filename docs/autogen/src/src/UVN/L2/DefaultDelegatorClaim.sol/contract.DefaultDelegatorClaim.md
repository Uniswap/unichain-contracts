# DefaultDelegatorClaim
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/31f7d1e84e305ebb14dd3f50a3450497938c6404/src/UVN/L2/DefaultDelegatorClaim.sol)

**Inherits:**
[IDefaultDelegatorClaim](/src/interfaces/UVN/L2/IDefaultDelegatorClaim.sol/interface.IDefaultDelegatorClaim.md)


## State Variables
### PERCENTAGE_DENOMINATOR

```solidity
uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
```


### PRECISION

```solidity
uint256 private constant PRECISION = 1e27;
```


### STAKE_TABLE

```solidity
address private immutable STAKE_TABLE;
```


### OPERATOR
Returns the operator


```solidity
address public immutable OPERATOR;
```


### operatorFeeManager
Returns the operator fee manager


```solidity
IOperatorFeeManager public operatorFeeManager;
```


### totalDelegation
Returns the total amount delegated to an operator


```solidity
uint256 public totalDelegation;
```


### delegationOf
Returns the amount delegated to an operator by a delegator


```solidity
mapping(address delegator => uint256 amount) public delegationOf;
```


### _globalCheckpoint

```solidity
uint256 private _globalCheckpoint;
```


### _checkpointOf

```solidity
mapping(address delegator => uint256 checkpoint) private _checkpointOf;
```


### _earnedRewardsOf

```solidity
mapping(address delegator => uint256 earnedRewards) private _earnedRewardsOf;
```


## Functions
### constructor


```solidity
constructor(address operator);
```

### receive

*Receives rewards from the reward distributor contract*

*If the operator has set an operator fee manager contract, the operator fee is calculated and handled by that contract, else no operator fee is applied*

*The remaining reward is distributed among all delegators*


```solidity
receive() external payable;
```

### reportDelegatorStake

*When an operator is slashed, delegator stakes are only updated when slashing is applied on L1*


```solidity
function reportDelegatorStake(address delegator, uint256 newDelegatorStake) external;
```

### setOperatorFeeManager

Sets the operator fee manager

*Only the operator can set the operator fee manager*


```solidity
function setOperatorFeeManager(IOperatorFeeManager operatorFeeManager_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operatorFeeManager_`|`IOperatorFeeManager`||


### claimRewards

Allows a delegator to claim their rewards

*The caller must be the delegator or an aliased address of the delegator from L1*


```solidity
function claimRewards(address delegator, address to) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|The address of the delegator|
|`to`|`address`|The address to send the rewards to|


### rewardsOf

Returns the rewards of a delegator


```solidity
function rewardsOf(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the delegator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The rewards of the delegator|


### _updateRewardCheckpoint

*Updates the reward checkpoint for an account and adds the reward to the earned rewards*


```solidity
function _updateRewardCheckpoint(address account) internal;
```

### _calculateReward

*Calculates the reward for an account based on the global checkpoint and the account's checkpoint*


```solidity
function _calculateReward(address account) internal view returns (uint256);
```

