# Attestations
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/d9df4316403fca3b5f27d3e66d0e0bee90626660/src/UVN/L2/libraries/AttestationLib.sol)


```solidity
struct Attestations {
    uint256 head;
    uint256 tail;
    mapping(uint256 blockNumber => Attestation) attestations;
}
```

