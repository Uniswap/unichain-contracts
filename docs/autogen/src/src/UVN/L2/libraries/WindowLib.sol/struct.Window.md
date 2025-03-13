# Window
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/b7383382c1ce8df5f5120f02338dfd44fd340bf2/src/UVN/L2/libraries/WindowLib.sol)


```solidity
struct Window {
    bool finalized;
    uint256 rewardETH;
    uint256 votingTotalSupply;
    bytes32 blockHash;
    bytes32 mostVotedBlockHash;
    bytes32 mostVotedHash;
    uint256 mostVotedHashVotes;
    NextWindow nextWindow;
    uint256 index;
    mapping(bytes32 votedHash => uint256 votes) attestations;
}
```

