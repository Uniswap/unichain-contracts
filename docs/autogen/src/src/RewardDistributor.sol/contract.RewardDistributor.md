# RewardDistributor
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/01f4e5565a975be8c899959d029a1dc7e641a28e/src/RewardDistributor.sol)


## State Variables
### ATTESTATION_PERIOD
*The number of blocks attesters have to vote on a block*


```solidity
uint256 public constant ATTESTATION_PERIOD = 10;
```


### PAYMENT_SPLITTER
*The address of the payment splitter contract that receives sequencer rewards.*


```solidity
address private immutable PAYMENT_SPLITTER;
```


### L2_STAKE_MANAGER

```solidity
L2StakeManager private immutable L2_STAKE_MANAGER;
```


### _blocks

```solidity
mapping(uint256 blockNumber => Block) private _blocks;
```


### _rewards

```solidity
mapping(address user => Reward) private _rewards;
```


## Functions
### constructor


```solidity
constructor(address paymentSplitter, address l2StakeManager);
```

### receive

*Receives rewards from the payment splitter contract for the current block.*

*Stores the block hash of the previous block.*


```solidity
receive() external payable;
```

### attest


```solidity
function attest(uint256 blockNumber, bytes32 blockHash, bool vote) external;
```

### withdraw


```solidity
function withdraw(address recipient) external;
```

### finalize


```solidity
function finalize(address account, uint256 n) external;
```

### isFinalized


```solidity
function isFinalized(uint256 blockNumber) public view returns (bool);
```

### earned


```solidity
function earned(address account) public view returns (uint256);
```

### _finalizeNext


```solidity
function _finalizeNext(address account) internal;
```

### _encodeNext


```solidity
function _encodeNext(uint256 blockNumber, bool vote) private pure returns (uint256);
```

### _decodeNext


```solidity
function _decodeNext(uint256 next) private pure returns (uint256 blockNumber, bool vote);
```

## Events
### RewardDeposited

```solidity
event RewardDeposited(uint256 indexed blockNumber, uint256 reward);
```

### Attested

```solidity
event Attested(uint256 indexed blockNumber, address indexed user, bytes32 blockHash, bool vote);
```

### Finalized

```solidity
event Finalized(uint256 indexed blockNumber, address indexed user, uint256 amount);
```

### Withdrawn

```solidity
event Withdrawn(address indexed user, uint256 amount);
```

## Errors
### Unauthorized

```solidity
error Unauthorized();
```

### InvalidBlockNumber

```solidity
error InvalidBlockNumber();
```

### InvalidBlockHash

```solidity
error InvalidBlockHash();
```

### AttestationPeriodExpired

```solidity
error AttestationPeriodExpired();
```

### AttestationOutOfOrder

```solidity
error AttestationOutOfOrder();
```

### TransferFailed

```solidity
error TransferFailed();
```

## Structs
### Block

```solidity
struct Block {
    uint256 reward;
    bytes32 blockHash;
    uint256 votesFor;
    uint256 votesAgainst;
}
```

### Reward

```solidity
struct Reward {
    uint256 earned;
    uint256 head;
    uint256 tail;
    mapping(uint256 blockNumber => uint256 next) next;
}
```

