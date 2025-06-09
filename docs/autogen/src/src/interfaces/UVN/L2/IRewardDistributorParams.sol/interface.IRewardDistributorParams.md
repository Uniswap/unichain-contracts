# IRewardDistributorParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/3acb5f12419bea9fea7cca34c0464a9cc73593b7/src/interfaces/UVN/L2/IRewardDistributorParams.sol)

This contract is a base contract for the reward distributor contract. It manages the parameters required for attestations and reward distribution.


## Functions
### setAttestationWindowLength

Update the attestation window length


```solidity
function setAttestationWindowLength(uint256 newAttestationWindowLength) external;
```

### setAttestationPeriod

Update the attestation period


```solidity
function setAttestationPeriod(uint256 newAttestationPeriod) external;
```

### setRewardPuller

Update the reward puller contract


```solidity
function setRewardPuller(IRewardPuller newRewardPuller) external;
```

### attestationWindowLength

The attestation window length determines the amount of blocks an operator is attesting to

*Attestations are made to the last block of a given window*


```solidity
function attestationWindowLength() external view returns (uint256);
```

### attestationPeriod

The attestation period determines the amount of blocks an operator has to attest to an active window before it gets finalized


```solidity
function attestationPeriod() external view returns (uint256);
```

### rewardPuller

The reward puller contract is called whenever a new window is scheduled to fetch the rewards for the previous window

*The reward puller contract must implement the `IRewardPuller` interface*


```solidity
function rewardPuller() external view returns (IRewardPuller);
```

### PARAM_SETTER_ROLE

The role required to update the attestation window length, attestation period, and reward puller contract


```solidity
function PARAM_SETTER_ROLE() external view returns (bytes32);
```

## Events
### AttestationWindowLengthUpdated
Emitted when the attestation window length is updated


```solidity
event AttestationWindowLengthUpdated(uint256 oldAttestationWindowLength, uint256 newAttestationWindowLength);
```

### AttestationPeriodUpdated
Emitted when the attestation period is updated


```solidity
event AttestationPeriodUpdated(uint256 oldAttestationPeriod, uint256 newAttestationPeriod);
```

### RewardPullerUpdated
Emitted when the reward puller contract is updated


```solidity
event RewardPullerUpdated(address oldRewardPuller, address newRewardPuller);
```

## Errors
### AmountZero

```solidity
error AmountZero();
```

### AttestationWindowLengthTooLarge
Only the last 256 blockhashes are available, limiting the attestation window length to 256 blocks


```solidity
error AttestationWindowLengthTooLarge();
```

### AttestationPeriodTooShort
The attestation period must be at least as long as the attestation window length to ensure that active windows can always be attested to


```solidity
error AttestationPeriodTooShort();
```

### InvalidRewardPuller
The reward puller must implement the `IRewardPuller` interface


```solidity
error InvalidRewardPuller();
```

