# RewardDistributorParams
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/b7383382c1ce8df5f5120f02338dfd44fd340bf2/src/UVN/L2/RewardDistributorParams.sol)

**Inherits:**
AccessControl, [IRewardDistributorParams](/src/interfaces/UVN/L2/IRewardDistributorParams.sol/interface.IRewardDistributorParams.md)


## State Variables
### PARAM_SETTER_ROLE

```solidity
bytes32 public constant PARAM_SETTER_ROLE = keccak256('PARAM_SETTER_ROLE');
```


### _attestationPeriod

```solidity
uint256 private _attestationPeriod;
```


### _rewardPuller

```solidity
IRewardPuller private _rewardPuller;
```


### _windows

```solidity
Windows internal _windows;
```


## Functions
### constructor


```solidity
constructor(address admin, uint256 attestationWindowLength_, uint256 attestationPeriod_, IRewardPuller rewardPuller_);
```

### setAttestationWindowLength

Update the attestation window length


```solidity
function setAttestationWindowLength(uint256 newAttestationWindowLength) external onlyRole(PARAM_SETTER_ROLE);
```

### setAttestationPeriod

Update the attestation period


```solidity
function setAttestationPeriod(uint256 newAttestationPeriod) external onlyRole(PARAM_SETTER_ROLE);
```

### setRewardPuller

Update the reward puller contract


```solidity
function setRewardPuller(IRewardPuller newRewardPuller) external onlyRole(PARAM_SETTER_ROLE);
```

### attestationWindowLength

The attestation window length determines the amount of blocks an operator is attesting to

*Attestations are made to the last block of a given window*


```solidity
function attestationWindowLength() public view returns (uint256);
```

### attestationPeriod

The attestation period determines the amount of blocks an operator has to attest to an active window before it gets finalized


```solidity
function attestationPeriod() public view returns (uint256);
```

### rewardPuller

The reward puller contract is called whenever a new window is scheduled to fetch the rewards for the previous window

*The reward puller contract must implement the `IRewardPuller` interface*


```solidity
function rewardPuller() public view returns (IRewardPuller);
```

### _setAttestationWindowLength


```solidity
function _setAttestationWindowLength(uint256 newAttestationWindowLength) internal;
```

### _setAttestationPeriod


```solidity
function _setAttestationPeriod(uint256 newAttestationPeriod) internal;
```

### _setRewardPuller


```solidity
function _setRewardPuller(IRewardPuller newRewardPuller) internal;
```

### _window


```solidity
function _window(uint256 blockNumber) internal view returns (Window storage);
```

