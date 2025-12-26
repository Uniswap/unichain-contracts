# Unichain Contracts

## Overview

This repository contains the core Unichain protocol contracts, including the fee distribution system. The system automatically collects fees from L2 fee vaults, calculates revenue shares, and distributes them to Optimism, L1 recipients, and net fee recipients.

### Fee Flow

```
L2 Fee Vaults (Optimism Standard)
├── Sequencer Fee Vault
├── Base Fee Vault
└── L1 Fee Vault
        │
        ▼
    FeeSplitter
    (calculates Optimism's share)
        │
        ├──▶ Optimism Wallet (15% of net OR 2.5% of gross, whichever is higher)
        ├──▶ L1Splitter ──▶ L2StandardBridge ──▶ L1 Recipient
        └──▶ NetFeeSplitter
                │
                └──▶ Recipients (with allocations)
                        └──▶ FeeRecipientForwarder ──▶ TokenJar
```

## Contracts

### Core Contracts

| Contract           | Description                                                                                                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **FeeSplitter**    | Primary contract that withdraws ETH from three L2 fee vaults and orchestrates fee distribution. Calculates Optimism's revenue share (max of 15% net or 2.5% gross). |
| **L1Splitter**     | Manages L1 fee distribution by bridging fees to L1 via the L2 Standard Bridge. Includes configurable withdrawal intervals and minimum amounts for gas efficiency.   |
| **NetFeeSplitter** | Distributes net fees (sequencer + base fees) among multiple recipients with customizable allocations. Uses an index-based mechanism for efficient distribution.     |
| **L1NetRecipient** | Combines L1Splitter functionality with NetFeeSplitter withdrawal capability for pulling fees before bridging to L1.                                                 |

### Periphery Contracts

| Contract                  | Description                                                                                               |
| ------------------------- | --------------------------------------------------------------------------------------------------------- |
| **FeeRecipientForwarder** | A recipient contract for NetFeeSplitter that forwards withdrawn fees to another address (e.g., TokenJar). |

#### FeeRecipientForwarder

Post Unification all sequencer fees are sent to the TokenJar via the FeeRecipientForwarder. Anyone can call `withdraw` on the FeeRecipientForwarder to send the fees to the TokenJar at any time. Accrued fees to the TokenJar can be checked via the `earnedFees(feeRecipientForwarder)` function.

## Deployed Contract Addresses (Unichain Mainnet)

### Unichain Custom Contracts

| Contract              | Address                                      | Description                                                                   |
| --------------------- | -------------------------------------------- | ----------------------------------------------------------------------------- |
| FeeSplitter           | `0x4300c0D3c0d3c0d3c0d3c0d3C0D3c0d3c0d30001` | Withdraws from fee vaults and distributes to Optimism, L1, and net recipients |
| L1Splitter (Optimism) | `0x4300C0D3C0D3C0D3C0d3C0d3c0d3C0d3C0d30002` | Bridges Optimism's revenue share to L1                                        |
| L1Splitter (L1 Fees)  | `0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003` | Bridges L1 fee revenue to L1                                                  |
| NetFeeSplitter        | `0x4300c0D3c0D3c0D3c0D3c0D3C0D3c0d3c0D30004` | Distributes net fees among recipients based on their allocation               |
| FeeRecipientForwarder | `0x7A6f67B6042Ca34B01E0DeC6FeaD644CD3b8C235` | Forwards fees from NetFeeSplitter to TokenJar                                 |
| TokenJar              | `0xD576BDF6b560079a4c204f7644e556DbB19140b5` | Receives forwarded fees for distribution                                      |

### Optimism Standard Predeploys

| Contract          | Address                                      | Description                  |
| ----------------- | -------------------------------------------- | ---------------------------- |
| SequencerFeeVault | `0x4200000000000000000000000000000000000011` | Collects sequencer fees      |
| BaseFeeVault      | `0x4200000000000000000000000000000000000019` | Collects base fees           |
| L1FeeVault        | `0x420000000000000000000000000000000000001A` | Collects L1 data fees        |
| L2StandardBridge  | `0x4200000000000000000000000000000000000010` | Bridges assets from L2 to L1 |

## Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

```shell
forge install
forge build
```

### Testing

```shell
forge test
```

For fork tests against Unichain mainnet:

```shell
UNICHAIN_RPC_URL=<your_rpc_url> forge test
```

## Deployment

Deploy contracts using versioned deployment scripts:

```shell
forge script script/Deploy.s.sol --broadcast --rpc-url <rpc_url> --verify
```

See [CONTRIBUTING.md](CONTRIBUTING.md#deployment) for detailed deployment instructions.

## Documentation

- [Architecture Documentation](docs/)
- [Auto-generated NatSpec Documentation](docs/autogen/src/src/)

When exploring the contracts, start with the interfaces in `src/interfaces/` before reviewing implementations.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this repository.

## License

MIT
