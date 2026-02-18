// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "./Currency.sol";
import {IHooks} from "../interfaces/IHooks.sol";

/// @title PoolKey — uniquely identifies a pool
/// @notice A pool is identified by its two currencies, fee, tick spacing, and hooks contract
struct PoolKey {
    /// @notice The lower currency of the pool, sorted numerically
    Currency currency0;
    /// @notice The higher currency of the pool, sorted numerically
    Currency currency1;
    /// @notice The pool LP fee, capped at 1_000_000 (100%)
    /// @dev If the top bit is set (0x800000), the fee is dynamic and must be queried from hooks
    uint24 fee;
    /// @notice Ticks can only be used at multiples of this value, determines granularity
    /// @dev Must be positive; limits max liquidity per tick
    int24 tickSpacing;
    /// @notice The hooks contract for this pool
    IHooks hooks;
}

using PoolKeyLibrary for PoolKey global;

library PoolKeyLibrary {
    /// @notice Returns the pool key with currencies sorted
    function toId(PoolKey memory poolKey) internal pure returns (bytes32 poolId) {
        assembly ("memory-safe") {
            poolId := keccak256(poolKey, mul(32, 5))
        }
    }
}
