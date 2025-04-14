# AttestationLib
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/d9df4316403fca3b5f27d3e66d0e0bee90626660/src/UVN/L2/libraries/AttestationLib.sol)

A linked list of attestations for an operator


## Functions
### push

Add an attestation to the linked list


```solidity
function push(Attestations storage $, uint256 blockNumber, bytes32 votedHash, uint256 votes) internal;
```

### nextBlockNumber

Get the next block number an operator has attested to


```solidity
function nextBlockNumber(Attestations storage $) internal returns (uint256 blockNumber);
```

### getVotes

Get the votes and voted hash for a given block number


```solidity
function getVotes(Attestations storage $, uint256 blockNumber)
    internal
    view
    returns (uint256 votes, bytes32 votedHash);
```

### finalize

Called when the reward for this window is distributed

Must be called in order


```solidity
function finalize(Attestations storage $, uint256 blockNumber) internal;
```

