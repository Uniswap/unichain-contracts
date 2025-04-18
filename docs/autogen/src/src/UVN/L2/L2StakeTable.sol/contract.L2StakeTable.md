# L2StakeTable
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/31f7d1e84e305ebb14dd3f50a3450497938c6404/src/UVN/L2/L2StakeTable.sol)

**Inherits:**
[IL2StakeTable](/src/interfaces/UVN/L2/IL2StakeTable.sol/interface.IL2StakeTable.md), [Votes](/src/UVN/L1/StakingMiddleware/libraries/Votes.sol/abstract.Votes.md)

This contract is a clone of the L1 stake table. Whenever the balance of an operator changes on L1, this contract is notified and the balance is updated on L2. This contract deploys a default contract for delegators to claim rewards when the ERC-721 token is deposited on L1. This contract is then notified of subsequent stake changes on L1. Operators can override the default delegator claim contract with a custom implementation to distribute rewards differently.


## State Variables
### MIN_DELEGATOR_UPDATE_GAS

```solidity
uint256 private constant MIN_DELEGATOR_UPDATE_GAS = 200_000;
```


### PERCENTAGE_DENOMINATOR

```solidity
uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
```


### L1_STAKE_TABLE_SYNC

```solidity
address public immutable L1_STAKE_TABLE_SYNC;
```


### _delegatorClaims

```solidity
mapping(address operator => IDelegatorClaim delegatorClaim) internal _delegatorClaims;
```


## Functions
### onlyL1StakeTableSync


```solidity
modifier onlyL1StakeTableSync();
```

### constructor

*The contract needs to be deployed via create3 to make the address deterministic and not dependent on the l1 stake table sync address*

*The address offset needs to be applied to the l1 stake table sync address*


```solidity
constructor(address l1StakeTableSync) EIP712('L2StakeTable', '1');
```

### reportOperatorStake

This function is called when a delegator's stake changes.

*Only callable by the L1 stake table sync contract*

*Called by the L1 stake table sync contract when an operator's stake changes*

*Updates the operator's voting units*

*Notifies delegator claim contracts of delegator stake changes*

*Should an operator already have delegators when depositing their ERC-721 token, the balances of existing delegators need to be synced manually*


```solidity
function reportOperatorStake(address operator, uint256 newBalance, address delegator, uint256 newDelegatorStake)
    external
    onlyL1StakeTableSync;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|
|`newBalance`|`uint256`|The new balance of the operator.|
|`delegator`|`address`|The address of the delegator.|
|`newDelegatorStake`|`uint256`|The new stake of the delegator.|


### reportOperatorSlash

This function is called when an operator is slashed.

*Only callable by the L1 stake table sync contract*

*Called by the L1 stake table sync contract when an operator is slashed*

*Updates the operator's voting units according to the remaining percentage of the stake*


```solidity
function reportOperatorSlash(address operator, uint256 remainingPercentage) external onlyL1StakeTableSync;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|
|`remainingPercentage`|`uint256`|The remaining percentage of the operator's stake.|


### onWithdrawal

This function is called when an operator ERC-721 token is transferred away from the service contract.

*Only callable by the L1 stake table sync contract*

*Called by the L1 stake table sync contract when an operator withdraws their ERC-721 token*

*Sets the operator's voting units to 0*


```solidity
function onWithdrawal(address operator) external onlyL1StakeTableSync;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|


### overrideDelegatorClaimContract

Sets a delegator claim contract for an operator

*Allows an operator to override the default delegator claim contract with a custom implementation*


```solidity
function overrideDelegatorClaimContract(IDelegatorClaim delegatorClaim) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegatorClaim`|`IDelegatorClaim`|The delegator claim contract to set|


### beneficiary

Returns the beneficiary address to receive rewards for the given operator address


```solidity
function beneficiary(address operator) external view override returns (address);
```

### _setDelegatorClaimContract

*Sets a delegator claim contract for an operator*


```solidity
function _setDelegatorClaimContract(address operator, IDelegatorClaim delegatorClaim) internal;
```

### delegate

*Disable delegation*


```solidity
function delegate(address) public pure override(Votes, IVotes);
```

### delegateBySig

*Disable delegation*


```solidity
function delegateBySig(address, uint256, uint256, uint8, bytes32, bytes32) public pure override(Votes, IVotes);
```

### delegates

*Auto delegate to self*


```solidity
function delegates(address account) public view virtual override(Votes, IVotes) returns (address);
```

### _getVotingUnits


```solidity
function _getVotingUnits(address account) internal view virtual override returns (uint256);
```

