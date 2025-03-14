# Window
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/2ace9652edc8281c369320073e8ddf578dff2d07/src/UVN/L2/libraries/WindowLib.sol)


```solidity
struct Window {
    bool finalized;
    uint96 rewardETH;
    uint32 index;
    uint96 votingTotalSupply;
    uint96 mostVotedHashVotes;
    NextWindow nextWindow;
    bytes32 blockHash;
    bytes32 mostVotedBlockHash;
    bytes32 mostVotedHash;
    mapping(bytes32 votedHash => uint256 votes) attestations;
}
```

