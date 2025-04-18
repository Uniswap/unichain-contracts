# ExampleOperatorFeeManager
[Git Source](https://github.com/Uniswap/unichain-contracts/blob/31f7d1e84e305ebb14dd3f50a3450497938c6404/src/UVN/L2/examples/ExampleOperatorFeeManager.sol)

**Inherits:**
[IOperatorFeeManager](/src/interfaces/UVN/L2/IOperatorFeeManager.sol/interface.IOperatorFeeManager.md)

This contract is called by the DefaultDelegatorClaim to calculate the operator fee for a given reward received by delegators. Arbitrary logic can be implemented to calculate the operator fee as well as the distribution of the fee to the operator.


## State Variables
### PERCENTAGE_DENOMINATOR

```solidity
uint256 private constant PERCENTAGE_DENOMINATOR = 1e18;
```


### OPERATOR

```solidity
address public immutable OPERATOR;
```


### OPERATOR_FEE

```solidity
uint256 public immutable OPERATOR_FEE;
```


## Functions
### constructor


```solidity
constructor(address operator, uint256 operatorFee_);
```

### receive

*Handles the fees received from the DefaultDelegatorClaim*

*The operator can implement arbitrary logic to distribute the fees to themselves, e.g., send them to the operator address or a cold storage, send fees based on certain rules, e.g., if a threshold is reached or the operator balance is below a certain amount, etc.*


```solidity
receive() external payable;
```

### operatorFee

*Calculates the operator fee for a given reward*

*Arbitrary logic to calculate the operator fee can be implemented here, e.g., a dynamic fee based on the current gas price, a tiered fee structure, etc.*


```solidity
function operatorFee(uint256 reward) external view returns (uint256);
```

