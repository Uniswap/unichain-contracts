# SlashingManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/24150a287633bc355fa0bd43e8e420b312a5ca02/src/UVN/L1/StakingMiddleware/SlashingManager.sol)

**Inherits:**
[OperatorManager](/src/UVN/L1/StakingMiddleware/OperatorManager.sol/abstract.OperatorManager.md)


## State Variables
### PERCENTAGE_DENOMINATOR

```solidity
uint96 private constant PERCENTAGE_DENOMINATOR = 1e18;
```


### _slashingData

```solidity
mapping(address operator => SlashingData data) internal _slashingData;
```


### _delegatorSlashingHead

```solidity
mapping(address delegator => bytes32 operatorTail) internal _delegatorSlashingHead;
```


## Functions
### selectOperator


```solidity
function selectOperator(address operator) public override;
```

### deselectOperator


```solidity
function deselectOperator() public override;
```

### slashAmount


```solidity
function slashAmount(address operator, uint96 amount) external onlyRole(SLASHER_ROLE());
```

### slashPercentage


```solidity
function slashPercentage(address operator, uint96 percentage) external onlyRole(SLASHER_ROLE());
```

### applySlashing


```solidity
function applySlashing(address delegator, uint256 n) public;
```

### isDelegatorSlashed


```solidity
function isDelegatorSlashed(address delegator) external view returns (bool);
```

### delegatorStake


```solidity
function delegatorStake(address delegator) public view override returns (uint96);
```

### _slash


```solidity
function _slash(address operator, uint96 remainingPercentage) internal;
```

### _calculateSlashing


```solidity
function _calculateSlashing(address delegator, uint256 n)
    internal
    view
    returns (uint96 newStake, bytes32 delegatorHead);
```

### _isDelegatorSlashed


```solidity
function _isDelegatorSlashed(bytes32 operatorTail, bytes32 delegatorHead) internal pure returns (bool);
```

### SLASHER_ROLE


```solidity
function SLASHER_ROLE() public view returns (bytes32);
```

## Structs
### SlashingInstance

```solidity
struct SlashingInstance {
    uint96 remainingPercentage;
    bytes32 next;
}
```

### SlashingData

```solidity
struct SlashingData {
    bytes32 head;
    bytes32 tail;
    mapping(bytes32 instanceHash => SlashingInstance instance) instances;
}
```

