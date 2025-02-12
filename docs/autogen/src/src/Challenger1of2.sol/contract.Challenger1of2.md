# Challenger1of2
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/2b39a73852bb4fead37417039aa931063fb8280f/src/Challenger1of2.sol)

based off https://github.com/base-org/contracts/blob/4e227669098218ce50381f83ee3a611945913f62/src/Challenger1of2.sol, modified for the permissioned dispute game

*This contract serves the role of the Challenger.
It enforces a simple 1 of 2 design, where neither party can remove the other's
permissions to execute a Challenger call.*


## State Variables
### OP_SIGNER
*The address of Optimism's signer (likely a multisig)*


```solidity
address public immutable OP_SIGNER;
```


### OTHER_SIGNER
*The address of counter party's signer (likely a multisig)*


```solidity
address public immutable OTHER_SIGNER;
```


## Functions
### constructor

*Constructor to set the values of the constants.*


```solidity
constructor(address _opSigner, address _otherSigner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_opSigner`|`address`|Address of Optimism signer.|
|`_otherSigner`|`address`|Address of counter party signer.|


### execute

*Executes a call as the Challenger (must be called by
Optimism or counter party signer).*


```solidity
function execute(address _target, bytes memory _data) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_target`|`address`|Address to call.|
|`_data`|`bytes`|Data for function call.|


## Events
### ChallengerCallExecuted
*Emitted when a Challenger call is made by a signer.*


```solidity
event ChallengerCallExecuted(
    address indexed _caller, address indexed _target, uint256 _value, bytes _data, bytes _result
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_caller`|`address`|The signer making the call.|
|`_target`|`address`|The target address of the call.|
|`_value`|`uint256`|The amount of ETH sent.|
|`_data`|`bytes`|The data of the call being made.|
|`_result`|`bytes`|The result of the call being made.|

