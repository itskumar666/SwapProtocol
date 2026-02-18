// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "../types/Currency.sol";

/// @title TransientStateLibrary — helpers for reading transient storage state from PoolManager
/// @notice Provides functions to read currency deltas and lock state from transient storage
/// @dev These map to the transient storage layout used by PoolManager
///
/// TRANSIENT STORAGE LAYOUT:
///   slot = keccak256(abi.encodePacked(caller, currency))  → int256 currencyDelta
///   LOCK_SLOT (constant) → uint256 isUnlocked (0 = locked, 1 = unlocked)
///   RESERVES_SLOT_BASE + uint160(currency) → uint256 reservesOf (synced balance)
///
library TransientStateLibrary {
    /// @dev The slot for the lock state. Must match PoolManager's constant.
    bytes32 internal constant IS_UNLOCKED_SLOT = bytes32(uint256(0));

    /// @notice Returns the currency delta for a caller/currency pair
    /// @dev LOGIC:
    ///   1. Compute slot = keccak256(abi.encodePacked(caller, uint256(uint160(Currency.unwrap(currency)))))
    ///   2. Call exttload(slot) on the PoolManager (address(this) inside PoolManager)
    ///   3. Cast to int256
    function getCurrencyDelta(address manager, address caller, Currency currency)
        internal
        view
        returns (int256 delta)
    {
        // TODO: Implement
        // Use the manager's exttload to read the transient slot
    }

    /// @notice Returns whether the PoolManager is currently unlocked
    /// @dev LOGIC: Read IS_UNLOCKED_SLOT from transient storage
    function isUnlocked(address manager) internal view returns (bool) {
        // TODO: Implement
    }

    /// @notice Returns the synced reserves for a currency
    /// @dev LOGIC: Read from the reserves transient storage slot
    function getReserves(address manager, Currency currency) internal view returns (uint256) {
        // TODO: Implement
    }

    /// @notice Returns the number of nonzero deltas that need to be settled
    /// @dev LOGIC: Read from the nonzero delta count transient storage slot
    function getNonzeroDeltaCount(address manager) internal view returns (uint256) {
        // TODO: Implement
    }
}
