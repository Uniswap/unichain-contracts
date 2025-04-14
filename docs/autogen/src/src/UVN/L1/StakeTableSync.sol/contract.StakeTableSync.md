# StakeTableSync
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/c6fb0d16c45440c99bf5e7d1fa8e991b11a08777/src/UVN/L1/StakeTableSync.sol)

**Inherits:**
[IStakeTableSync](/src/interfaces/UVN/L1/IStakeTableSync.sol/interface.IStakeTableSync.md), ERC165

This contract is used to sync the stake table of the StakingMiddleware contract to the L2. On notifications about slashing and balance changes from the StakingMiddleware, the data is forwarded to the StakeTable contract on L2. On deposits of operator ERC-721 tokens, the initial balance of the operator is reported to the StakeTable contract on L2. Should an operator already have delegators before depositing their operator token or should they withdraw their operator token and re-deposit it, inconsistencies in the stake of individual delegators could occur. This contract exposes two sync functions to forcefully sync the correct balances to L2.


## State Variables
### OPTIMISM_PORTAL

```solidity
IOptimismPortal2 public constant OPTIMISM_PORTAL = IOptimismPortal2(payable(0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2));
```


### STAKING_MIDDLEWARE

```solidity
IStakingMiddleware public immutable STAKING_MIDDLEWARE;
```


### L2_STAKE_TABLE

```solidity
address public immutable L2_STAKE_TABLE;
```


## Functions
### onlyStakingMiddleware


```solidity
modifier onlyStakingMiddleware();
```

### constructor


```solidity
constructor(IStakingMiddleware stakingMiddleware_, address l2StakeTable);
```

### reportOperatorStake

Reports the current stake of a delegator and their operator to L2

*Only callable by the StakingMiddleware*


```solidity
function reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
    external
    onlyStakingMiddleware;
```

### reportOperatorSlash

Reports a slashing incident to L2

*Only callable by the StakingMiddleware*


```solidity
function reportOperatorSlash(address operator, uint256 remainingPercentage) external onlyStakingMiddleware;
```

### onWithdrawal

Reports a withdrawal of an operator token to L2


```solidity
function onWithdrawal(address operator) external;
```

### sync

Syncs the current stake of a delegator and their operator to L2

*This function can be called to sync inconsistencies in the stake table*


```solidity
function sync(address delegator) external;
```

### syncOperator

Syncs the current total delegated stake of an operator to L2

*This function can be called to sync inconsistencies in the stake table*


```solidity
function syncOperator(address operator) public;
```

### onERC721Received

Called when an operator ERC-721 token is deposited

*Reports the initial balance of the operator to L2*


```solidity
function onERC721Received(address, address, uint256 tokenId, bytes calldata) external returns (bytes4);
```

### supportsInterface

Query if a contract implements an interface

*Interface identification is specified in ERC-165. This function
uses less than 30,000 gas.*


```solidity
function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|`true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise|


### _reportOperatorStake

Reports the current stake of a delegator and their operator to L2 with a default gas limit


```solidity
function _reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
    internal;
```

### _reportOperatorStake

Reports the current stake of a delegator and their operator to L2 with a custom gas limit


```solidity
function _reportOperatorStake(
    address operator,
    uint256 newBalance,
    address delegator,
    uint256 newDelegatorStake,
    uint64 gasLimit
) internal;
```

### _depositTransaction

Sends a transaction to the L2 StakeTable contract


```solidity
function _depositTransaction(bytes memory data, uint64 gasLimit) internal;
```

