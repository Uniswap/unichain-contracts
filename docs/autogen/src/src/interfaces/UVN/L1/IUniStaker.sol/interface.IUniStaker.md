# IUniStaker
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/9887a71fc43a47270ee0bd60eebd28cf4d53cffb/src/interfaces/UVN/L1/IUniStaker.sol)


## Functions
### setAdmin

Set the admin address.

*Caller must be the current admin.*


```solidity
function setAdmin(address _newAdmin) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newAdmin`|`address`|Address of the new admin.|


### setRewardNotifier

Enables or disables a reward notifier address.

*Caller must be the current admin.*


```solidity
function setRewardNotifier(address _rewardNotifier, bool _isEnabled) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardNotifier`|`address`|Address of the reward notifier.|
|`_isEnabled`|`bool`|`true` to enable the `_rewardNotifier`, or `false` to disable.|


### lastTimeRewardDistributed

Timestamp representing the last time at which rewards have been distributed, which is either the current timestamp (because rewards are still actively being streamed) or the time at which the reward duration ended (because all rewards to date have already been streamed).


```solidity
function lastTimeRewardDistributed() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Timestamp representing the last time at which rewards have been distributed.|


### rewardPerTokenAccumulated

Live value of the global reward per token accumulator. It is the sum of the last checkpoint value with the live calculation of the value that has accumulated in the interim. This number should monotonically increase over time as more rewards are distributed.


```solidity
function rewardPerTokenAccumulated() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Live value of the global reward per token accumulator.|


### unclaimedReward

Live value of the unclaimed rewards earned by a given beneficiary account. It is the sum of the last checkpoint value of their unclaimed rewards with the live calculation of the rewards that have accumulated for this account in the interim. This value can only increase, until it is reset to zero once the beneficiary account claims their unearned rewards.
Note that the contract tracks the unclaimed rewards internally with the scale factor included, in order to avoid the accrual of precision losses as users takes actions that cause rewards to be checkpointed. This external helper method is useful for integrations, and returns the value after it has been scaled down to the reward token's raw decimal amount.


```solidity
function unclaimedReward(address _beneficiary) external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Live value of the unclaimed rewards earned by a given beneficiary account.|


### stake

Stake tokens to a new deposit. The caller must pre-approve the staking contract to
spend at least the would-be staked amount of the token.

*The delegatee may not be the zero address. The deposit will be owned by the message sender, and the beneficiary will also be the message sender.*


```solidity
function stake(uint96 _amount, address _delegatee) external returns (DepositIdentifier);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint96`|The amount of the staking token to stake.|
|`_delegatee`|`address`|The address to assign the governance voting weight of the staked tokens.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`DepositIdentifier`|_depositId The unique identifier for this deposit.|


### stake

Method to stake tokens to a new deposit. The caller must pre-approve the staking
contract to spend at least the would-be staked amount of the token.

*Neither the delegatee nor the beneficiary may be the zero address. The deposit will be
owned by the message sender.*


```solidity
function stake(uint96 _amount, address _delegatee, address _beneficiary)
    external
    returns (DepositIdentifier _depositId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint96`|Quantity of the staking token to stake.|
|`_delegatee`|`address`|Address to assign the governance voting weight of the staked tokens.|
|`_beneficiary`|`address`|Address that will accrue rewards for this stake.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier for this deposit.|


### permitAndStake

Method to stake tokens to a new deposit. Before the staking operation occurs, a signature is passed to the token contract's permit method to spend the would-be staked amount of the token.

*Neither the delegatee nor the beneficiary may be the zero address. The deposit will be
owned by the message sender.*


```solidity
function permitAndStake(
    uint96 _amount,
    address _delegatee,
    address _beneficiary,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
) external returns (DepositIdentifier _depositId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint96`|Quantity of the staking token to stake.|
|`_delegatee`|`address`|Address to assign the governance voting weight of the staked tokens.|
|`_beneficiary`|`address`|Address that will accrue rewards for this stake.|
|`_deadline`|`uint256`|The timestamp after which the permit signature should expire.|
|`_v`|`uint8`|ECDSA signature component: Parity of the `y` coordinate of point `R`|
|`_r`|`bytes32`|ECDSA signature component: x-coordinate of `R`|
|`_s`|`bytes32`|ECDSA signature component: `s` value of the signature|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier for this deposit.|


### stakeOnBehalf

Stake tokens to a new deposit on behalf of a user, using a signature to validate the user's intent. The caller must pre-approve the staking contract to spend at least the would-be staked amount of the token.

*Neither the delegatee nor the beneficiary may be the zero address.*


```solidity
function stakeOnBehalf(
    uint96 _amount,
    address _delegatee,
    address _beneficiary,
    address _depositor,
    uint256 _deadline,
    bytes memory _signature
) external returns (DepositIdentifier _depositId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint96`|Quantity of the staking token to stake.|
|`_delegatee`|`address`|Address to assign the governance voting weight of the staked tokens.|
|`_beneficiary`|`address`|Address that will accrue rewards for this stake.|
|`_depositor`|`address`|Address of the user on whose behalf this stake is being made.|
|`_deadline`|`uint256`|The timestamp after which the signature should expire.|
|`_signature`|`bytes`|Signature of the user authorizing this stake.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier for this deposit.|


### stakeMore

Add more staking tokens to an existing deposit. A staker should call this method when they have an existing deposit, and wish to stake more while retaining the same delegatee and beneficiary.

*The message sender must be the owner of the deposit.*


```solidity
function stakeMore(DepositIdentifier _depositId, uint96 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit to which stake will be added.|
|`_amount`|`uint96`|Quantity of stake to be added.|


### permitAndStakeMore

Add more staking tokens to an existing deposit. A staker should call this method when they have an existing deposit, and wish to stake more while retaining the same delegatee and beneficiary. Before the staking operation occurs, a signature is passed to the token contract's permit method to spend the would-be staked amount of the token.

*The message sender must be the owner of the deposit.*


```solidity
function permitAndStakeMore(
    DepositIdentifier _depositId,
    uint96 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit to which stake will be added.|
|`_amount`|`uint96`|Quantity of stake to be added.|
|`_deadline`|`uint256`|The timestamp after which the permit signature should expire.|
|`_v`|`uint8`|ECDSA signature component: Parity of the `y` coordinate of point `R`|
|`_r`|`bytes32`|ECDSA signature component: x-coordinate of `R`|
|`_s`|`bytes32`|ECDSA signature component: `s` value of the signature|


### stakeMoreOnBehalf

Add more staking tokens to an existing deposit on behalf of a user, using a signature to validate the user's intent. A staker should call this method when they have an existing deposit, and wish to stake more while retaining the same delegatee and beneficiary.


```solidity
function stakeMoreOnBehalf(
    DepositIdentifier _depositId,
    uint96 _amount,
    address _depositor,
    uint256 _deadline,
    bytes memory _signature
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit to which stake will be added.|
|`_amount`|`uint96`|Quantity of stake to be added.|
|`_depositor`|`address`|Address of the user on whose behalf this stake is being made.|
|`_deadline`|`uint256`|The timestamp after which the signature should expire.|
|`_signature`|`bytes`|Signature of the user authorizing this stake.|


### alterDelegatee

For an existing deposit, change the address to which governance voting power is assigned.

*The new delegatee may not be the zero address. The message sender must be the owner of the deposit.*


```solidity
function alterDelegatee(DepositIdentifier _depositId, address _newDelegatee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit which will have its delegatee altered.|
|`_newDelegatee`|`address`|Address of the new governance delegate.|


### alterDelegateeOnBehalf

For an existing deposit, change the address to which governance voting power is assigned on behalf of a user, using a signature to validate the user's intent.

*The new delegatee may not be the zero address.*


```solidity
function alterDelegateeOnBehalf(
    DepositIdentifier _depositId,
    address _newDelegatee,
    address _depositor,
    uint256 _deadline,
    bytes memory _signature
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit which will have its delegatee altered.|
|`_newDelegatee`|`address`|Address of the new governance delegate.|
|`_depositor`|`address`|Address of the user on whose behalf this stake is being made.|
|`_deadline`|`uint256`|The timestamp after which the signature should expire.|
|`_signature`|`bytes`|Signature of the user authorizing this stake.|


### alterBeneficiary

For an existing deposit, change the beneficiary to which staking rewards are accruing.

*The new beneficiary may not be the zero address. The message sender must be the owner of the deposit.*


```solidity
function alterBeneficiary(DepositIdentifier _depositId, address _newBeneficiary) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit which will have its beneficiary altered.|
|`_newBeneficiary`|`address`|Address of the new rewards beneficiary.|


### alterBeneficiaryOnBehalf

For an existing deposit, change the beneficiary to which staking rewards are accruing on behalf of a user, using a signature to validate the user's intent.

*The new beneficiary may not be the zero address.*


```solidity
function alterBeneficiaryOnBehalf(
    DepositIdentifier _depositId,
    address _newBeneficiary,
    address _depositor,
    uint256 _deadline,
    bytes memory _signature
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit which will have its beneficiary altered.|
|`_newBeneficiary`|`address`|Address of the new rewards beneficiary.|
|`_depositor`|`address`|Address of the user on whose behalf this stake is being made.|
|`_deadline`|`uint256`|The timestamp after which the signature should expire.|
|`_signature`|`bytes`|Signature of the user authorizing this stake.|


### withdraw

Withdraw staked tokens from an existing deposit.

*The message sender must be the owner of the deposit. Stake is withdrawn to the message sender's account.*


```solidity
function withdraw(DepositIdentifier _depositId, uint96 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit from which stake will be withdrawn.|
|`_amount`|`uint96`|Quantity of staked token to withdraw.|


### withdrawOnBehalf

Withdraw staked tokens from an existing deposit on behalf of a user, using a signature to validate the user's intent.

*Stake is withdrawn to the deposit owner's account.*


```solidity
function withdrawOnBehalf(
    DepositIdentifier _depositId,
    uint96 _amount,
    address _depositor,
    uint256 _deadline,
    bytes memory _signature
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositId`|`DepositIdentifier`|Unique identifier of the deposit from which stake will be withdrawn.|
|`_amount`|`uint96`|Quantity of staked token to withdraw.|
|`_depositor`|`address`|Address of the user on whose behalf this stake is being made.|
|`_deadline`|`uint256`|The timestamp after which the signature should expire.|
|`_signature`|`bytes`|Signature of the user authorizing this stake.|


### claimReward

Claim reward tokens the message sender has earned as a stake beneficiary. Tokens are sent to the message sender.


```solidity
function claimReward() external returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of reward tokens claimed.|


### claimRewardOnBehalf

Claim earned reward tokens for a beneficiary, using a signature to validate the beneficiary's intent. Tokens are sent to the beneficiary.


```solidity
function claimRewardOnBehalf(address _beneficiary, uint256 _deadline, bytes memory _signature)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|Address of the beneficiary who will receive the reward.|
|`_deadline`|`uint256`|The timestamp after which the signature should expire.|
|`_signature`|`bytes`|Signature of the beneficiary authorizing this reward claim.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of reward tokens claimed.|


### notifyRewardAmount

Called by an authorized rewards notifier to alert the staking contract that a new reward has been transferred to it. It is assumed that the reward has already been transferred to this staking contract before the rewards notifier calls this method.

*It is critical that only well behaved contracts are approved by the admin to call this method, for two reasons.
1. A misbehaving contract could grief stakers by frequently notifying this contract of tiny rewards, thereby continuously stretching out the time duration over which real rewards are distributed. It is required that reward notifiers supply reasonable rewards at reasonable intervals.
2. A misbehaving contract could falsely notify this contract of rewards that were not actually distributed, creating a shortfall for those claiming their rewards after others. It is required that a notifier contract always transfers the `_amount` to this contract before calling this method.*


```solidity
function notifyRewardAmount(uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Quantity of reward tokens the staking contract is being notified of.|


### REWARD_TOKEN

ERC20 token in which rewards are denominated and distributed.


```solidity
function REWARD_TOKEN() external view returns (IERC20);
```

### STAKE_TOKEN

Delegable governance token which users stake to earn rewards.


```solidity
function STAKE_TOKEN() external view returns (IERC20Delegates);
```

### REWARD_DURATION

Length of time over which rewards sent to this contract are distributed to stakers.


```solidity
function REWARD_DURATION() external view returns (uint256);
```

### SCALE_FACTOR

Scale factor used in reward calculation math to reduce rounding errors caused by truncation during division.


```solidity
function SCALE_FACTOR() external view returns (uint256);
```

### nextDepositId

*Unique identifier that will be used for the next deposit.*


```solidity
function nextDepositId() external view returns (DepositIdentifier);
```

### rewardNotifier

Permissioned actor that can enable/disable `rewardNotifier` addresses.


```solidity
function rewardNotifier() external view returns (address);
```

### totalStaked

Global amount currently staked across all deposits.


```solidity
function totalStaked() external view returns (uint256);
```

### depositorTotalStaked

Tracks the total staked by a depositor across all unique deposits.


```solidity
function depositorTotalStaked(address) external view returns (uint256);
```

### earningPower

Tracks the total stake actively earning rewards for a given beneficiary account.


```solidity
function earningPower(address) external view returns (uint256);
```

### deposits

Stores the metadata associated with a given deposit.


```solidity
function deposits(DepositIdentifier) external view returns (Deposit memory);
```

### surrogates

Maps the account of each governance delegate with the surrogate contract which holds the staked tokens from deposits which assign voting weight to said delegate.


```solidity
function surrogates(address) external view returns (address);
```

### rewardEndTime

Time at which rewards distribution will complete if there are no new rewards.


```solidity
function rewardEndTime() external view returns (uint256);
```

### lastCheckpointTime

Last time at which the global rewards accumulator was updated.


```solidity
function lastCheckpointTime() external view returns (uint256);
```

### scaledRewardRate

Global rate at which rewards are currently being distributed to stakers, denominated in scaled reward tokens per second, using the SCALE_FACTOR.


```solidity
function scaledRewardRate() external view returns (uint256);
```

### rewardPerTokenAccumulatedCheckpoint

Checkpoint value of the global reward per token accumulator.


```solidity
function rewardPerTokenAccumulatedCheckpoint() external view returns (uint256);
```

### beneficiaryRewardPerTokenCheckpoint

Checkpoint of the reward per token accumulator on a per account basis. It represents the value of the global accumulator at the last time a given beneficiary's rewards were calculated and stored. The difference between the global value and this value can be used to calculate the interim rewards earned by given account.


```solidity
function beneficiaryRewardPerTokenCheckpoint(address) external view returns (uint256);
```

### beneficiaryUnclaimedRewardsCheckpoint

Checkpoint of the unclaimed rewards earned by a given beneficiary with the scale factor included. This value is stored any time an action is taken that specifically impacts the rate at which rewards are earned by a given beneficiary account. Total unclaimed rewards for an account are thus this value plus all rewards earned after this checkpoint was taken. This value is reset to zero when a beneficiary account claims their earned rewards.


```solidity
function beneficiaryUnclaimedRewardsCheckpoint(address) external view returns (uint256);
```

### isRewardNotifier

Maps addresses to whether they are authorized to call `notifyRewardAmount`.


```solidity
function isRewardNotifier(address) external view returns (bool);
```

### STAKE_TYPEHASH

Type hash used when encoding data for `stakeOnBehalf` calls.


```solidity
function STAKE_TYPEHASH() external view returns (bytes32);
```

### STAKE_MORE_TYPEHASH

Type hash used when encoding data for `stakeMoreOnBehalf` calls.


```solidity
function STAKE_MORE_TYPEHASH() external view returns (bytes32);
```

### ALTER_DELEGATEE_TYPEHASH

Type hash used when encoding data for `alterDelegateeOnBehalf` calls.


```solidity
function ALTER_DELEGATEE_TYPEHASH() external view returns (bytes32);
```

### ALTER_BENEFICIARY_TYPEHASH

Type hash used when encoding data for `alterBeneficiaryOnBehalf` calls.


```solidity
function ALTER_BENEFICIARY_TYPEHASH() external view returns (bytes32);
```

### WITHDRAW_TYPEHASH

Type hash used when encoding data for `withdrawOnBehalf` calls.


```solidity
function WITHDRAW_TYPEHASH() external view returns (bytes32);
```

### CLAIM_REWARD_TYPEHASH

Type hash used when encoding data for `claimRewardOnBehalf` calls.


```solidity
function CLAIM_REWARD_TYPEHASH() external view returns (bytes32);
```

## Events
### StakeDeposited
Emitted when stake is deposited by a depositor, either to a new deposit or one that already exists.


```solidity
event StakeDeposited(address owner, DepositIdentifier indexed depositId, uint256 amount, uint256 depositBalance);
```

### StakeWithdrawn
Emitted when a depositor withdraws some portion of stake from a given deposit.


```solidity
event StakeWithdrawn(DepositIdentifier indexed depositId, uint256 amount, uint256 depositBalance);
```

### DelegateeAltered
Emitted when a deposit's delegatee is changed.


```solidity
event DelegateeAltered(DepositIdentifier indexed depositId, address oldDelegatee, address newDelegatee);
```

### BeneficiaryAltered
Emitted when a deposit's beneficiary is changed.


```solidity
event BeneficiaryAltered(
    DepositIdentifier indexed depositId, address indexed oldBeneficiary, address indexed newBeneficiary
);
```

### RewardClaimed
Emitted when a beneficiary claims their earned reward.


```solidity
event RewardClaimed(address indexed beneficiary, uint256 amount);
```

### RewardNotified
Emitted when this contract is notified of a new reward.


```solidity
event RewardNotified(uint256 amount, address notifier);
```

### AdminSet
Emitted when the admin address is set.


```solidity
event AdminSet(address indexed oldAdmin, address indexed newAdmin);
```

### RewardNotifierSet
Emitted when a reward notifier address is enabled or disabled.


```solidity
event RewardNotifierSet(address indexed account, bool isEnabled);
```

### SurrogateDeployed
Emitted when a surrogate contract is deployed.


```solidity
event SurrogateDeployed(address indexed delegatee, address indexed surrogate);
```

## Errors
### UniStaker__Unauthorized
Thrown when an account attempts a call for which it lacks appropriate permission.


```solidity
error UniStaker__Unauthorized(bytes32 reason, address caller);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reason`|`bytes32`|Human readable code explaining why the call is unauthorized.|
|`caller`|`address`|The address that attempted the unauthorized call.|

### UniStaker__InvalidRewardRate
Thrown if the new rate after a reward notification would be zero.


```solidity
error UniStaker__InvalidRewardRate();
```

### UniStaker__InsufficientRewardBalance
Thrown if the following invariant is broken after a new reward: the contract should always have a reward balance sufficient to distribute at the reward rate across the reward duration.


```solidity
error UniStaker__InsufficientRewardBalance();
```

### UniStaker__InvalidAddress
Thrown if a caller attempts to specify address zero for certain designated addresses.


```solidity
error UniStaker__InvalidAddress();
```

### UniStaker__ExpiredDeadline
Thrown when an onBehalf method is called with a deadline that has expired.


```solidity
error UniStaker__ExpiredDeadline();
```

### UniStaker__InvalidSignature
Thrown if a caller supplies an invalid signature to a method that requires one.


```solidity
error UniStaker__InvalidSignature();
```

## Structs
### Deposit
Metadata associated with a discrete staking deposit.


```solidity
struct Deposit {
    uint96 balance;
    address owner;
    address delegatee;
    address beneficiary;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`uint96`|The deposit's staked balance.|
|`owner`|`address`|The owner of this deposit.|
|`delegatee`|`address`|The governance delegate who receives the voting weight for this deposit.|
|`beneficiary`|`address`|The address that accrues staking rewards earned by this deposit.|

