# OperatorVotes
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/ceada1ae0ce786b1a715a0c4cff008e665b4e9ed/src/UVN/L1/StakingMiddleware/libraries/OperatorVotes.sol)

**Inherits:**
[Votes](/src/UVN/L1/StakingMiddleware/libraries/Votes.sol/abstract.Votes.md)

This contract extends the Votes contract to be able to slash the operator votes directly, affecting the delegated votes of multiple delegators simultaneously.


## Functions
### _delegate

*when a delegator delegates to an operator the total supply of votes increases by the total stake of the delegator and vice versa for undelegating*


```solidity
function _delegate(address account, address delegatee) internal virtual override;
```

### _updateOperatorVotesAfterSlashing

*Slashes the operator votes (delegated votes of multiple delegators simultaneously), accepts the new amount of votes after slashing*


```solidity
function _updateOperatorVotesAfterSlashing(address operator, uint96 newVotes) internal virtual;
```

