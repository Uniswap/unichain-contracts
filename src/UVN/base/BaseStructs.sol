// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

struct OperatorData {
    uint96 sharesLast;
    uint96 sharesCurrent;
    uint32 lastSyncedBlock;
}
