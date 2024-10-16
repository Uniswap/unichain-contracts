# Documentation

## Fee Splitter Contracts

The fee splitter is divided into three contracts. The [FeeSplitter](../src/FeeSplitter/FeeSplitter.sol), [L1Splitter](../src/FeeSplitter/L1Splitter.sol), and [NetFeeSplitter](../src/FeeSplitter/NetFeeSplitter.sol). The responsibility of the fee splitter contracts is to withdraw fees from the l1, sequencer and base fee vaults and distribute them across all recipients.

### Fee Splitter

The FeeSplitter contract is the contract receiving all fees from the vaults. The main responsibility of the contract is to determine the amount of fees to send to the Optimism collective. The amount collected by Optimism is either 15% of the net revenue (sequencer + base fees) or 2.5% of the gross revenue (l1 + sequencer + base fees), depending on which is higher. The remaining l1 fees are then sent to the L1Splitter contract. The remaining net fees are sent to the NetFeeSplitter contract.

### L1 Splitter

The L1Splitter contract is the contract receiving all L1 fees. These fees are bridged back to L1. To avoid excessive gas costs to claim the fees on L1, the withdraw function is only callable once every specified interval as well as when the contract accumulates a minimum amount of fees. Currently, the L1Splitter contract does not actually split the fees between multiple recipients, however, the contract can be modified to do so in the future without changing the functionality of the remaining contracts.

### Net Fee Splitter

The NetFeeSplitter contract distributes the fees across an arbitrary number of recipients. Recipients accumulate their fees in a balance that can be withdrawn at any time. Recipients are managed by an admin. The admin can transfer their allocation or a portion of it to other recipients.
