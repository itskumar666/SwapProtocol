// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SafeCast} from "./SafeCast.sol";
import {TickMath} from "./TickMath.sol";

/// @title Tick — manages per-tick state for concentrated liquidity
/// @notice Each initialized tick stores liquidity, fee growth, and crossing metadata
library Tick {
    using SafeCast for int256;

    error TickLiquidityOverflow(int24 tick);
    error TicksMisordered(int24 tickLower, int24 tickUpper);
    error TickLowerOutOfBounds(int24 tickLower);
    error TickUpperOutOfBounds(int24 tickUpper);
    error TickNotAligned(int24 tick, int24 tickSpacing);

    // ═══════════════════════════════════════════════════════════
    //                       DATA STRUCTURES
    // ═══════════════════════════════════════════════════════════

    struct Info {
        /// @notice Total liquidity referencing this tick as either tickLower or tickUpper
        uint128 liquidityGross;
        /// @notice Net liquidity change when tick is crossed left-to-right
        /// @dev Positive when entering the tick range, negative when leaving
        int128 liquidityNet;
        /// @notice Fee growth per unit of liquidity on the *other* side of this tick (token0)
        /// @dev Used to compute how much fee a position has earned
        uint256 feeGrowthOutside0X128;
        /// @notice Fee growth per unit of liquidity on the *other* side of this tick (token1)
        uint256 feeGrowthOutside1X128;
    }

    // ═══════════════════════════════════════════════════════════
    //                       CONSTANTS
    // ═══════════════════════════════════════════════════════════

    /// @dev Maximum liquidity that can reference a single tick
    /// @dev = type(uint128).max / ((MAX_TICK - MIN_TICK) / tickSpacing)
    ///       but we use the per-spacing calculation in maxLiquidityPerTick()
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;

    // ═══════════════════════════════════════════════════════════
    //                       FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Validates that tickLower < tickUpper, both are within bounds, and both are multiples of tickSpacing
    /// @dev CHECKS:
    ///   1. tickLower < tickUpper                    → revert TicksMisordered
    ///   2. tickLower >= MIN_TICK                    → revert TickLowerOutOfBounds
    ///   3. tickUpper <= MAX_TICK                    → revert TickUpperOutOfBounds
    ///   4. tickLower % tickSpacing == 0             → revert TickNotAligned
    ///   5. tickUpper % tickSpacing == 0             → revert TickNotAligned
    function checkTicks(int24 tickLower, int24 tickUpper, int24 tickSpacing) internal pure {
        // TODO: Implement the 5 checks above
         require(tickLower < tickUpper                   , "TicksMisordered");
            require(tickLower >= MIN_TICK                 , "TickLowerOutOfBounds");
            require(tickUpper <= MAX_TICK                 , "TickUpperOutOfBounds");
            require(tickLower % tickSpacing == 0          , "TickNotAligned");
            require(tickUpper % tickSpacing == 0          , "TickNotAligned");
    }

    /// @notice Computes the maximum liquidity per tick for a given tick spacing
    /// @dev LOGIC:
    ///   1. Calculate minTick = (MIN_TICK / tickSpacing) * tickSpacing  (round towards zero)
    ///   2. Calculate maxTick = (MAX_TICK / tickSpacing) * tickSpacing
    ///   3. numTicks = (maxTick - minTick) / tickSpacing + 1
    ///   4. return type(uint128).max / numTicks
    function maxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128) {
        int24 minTick = (MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24(maxTick - minTick) / uint24(tickSpacing) + 1;
        return uint128(type(uint128).max / numTicks);
    }

    /// @notice Retrieves fee growth data for computing fees earned within a tick range
    /// @dev LOGIC — "fee growth inside" calculation:
    ///   Given: tickLower, tickUpper, tickCurrent, feeGrowthGlobal0X128, feeGrowthGlobal1X128
    ///
    ///   For each token (0 and 1):
    ///     if tickCurrent >= tickLower:
    ///       feeGrowthBelow = tick[tickLower].feeGrowthOutside
    ///     else:
    ///       feeGrowthBelow = feeGrowthGlobal - tick[tickLower].feeGrowthOutside
    ///
    ///     if tickCurrent < tickUpper:
    ///       feeGrowthAbove = tick[tickUpper].feeGrowthOutside
    ///     else:
    ///       feeGrowthAbove = feeGrowthGlobal - tick[tickUpper].feeGrowthOutside
    ///
    ///     feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove
    ///
    /// @return feeGrowthInside0X128 The fee growth inside the range for token0
    /// @return feeGrowthInside1X128 The fee growth inside the range for token1
    function getFeeGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        // TODO: Implement the fee growth inside calculation
        if(tickCurrent >= tickLower){
            feeGrowthInside0X128Lower = feeGrowthGlobal0X128 - self[tickLower].feeGrowthOutside0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - self[tickLower].feeGrowthOutside1X128;
        }
        else{
            feeGrowthInside0X128 = self[tickLower].feeGrowthOutside0X128;
            feeGrowthInside1X128 = self[tickLower].feeGrowthOutside1X128;
        }
        if(tickCurrent < tickUpper){
            feeGrowthInside0X128 -= self[tickUpper].feeGrowthOutside0X128;
            feeGrowthInside1X128 -= self[tickUpper].feeGrowthOutside1X128;
        }
        else{
            feeGrowthInside0X128 -= feeGrowthGlobal0X128 - self[tickUpper].feeGrowthOutside0X128;
            feeGrowthInside1X128 -= feeGrowthGlobal1X128 - self[tickUpper].feeGrowthOutside1X128;
        }
        uint256 feeGrowthInside0X128=feeGrowthGlobal0X128 - fee;
        return (feeGrowthInside0X128, feeGrowthInside1X128);
        // NOTE: All subtractions must be unchecked — fee growth counters intentionally overflow
    }

    /// @notice Updates a tick's state when liquidity is added or removed referencing this tick
    /// @dev LOGIC:
    ///   1. Load current info for 'tick' from self[tick]
    ///   2. liquidityGrossBefore = info.liquidityGross
    ///   3. liquidityGrossAfter = liquidityGrossBefore + liquidityDelta (use LiquidityMath.addDelta)
    ///   4. CHECK: liquidityGrossAfter <= maxLiquidity → revert TickLiquidityOverflow
    ///   5. flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0)
    ///      - flipped is true when tick transitions between initialized ↔ uninitialized
    ///   6. If liquidityGrossBefore == 0 (tick being initialized):
    ///      - if tick <= tickCurrent:
    ///          info.feeGrowthOutside0X128 = feeGrowthGlobal0X128
    ///          info.feeGrowthOutside1X128 = feeGrowthGlobal1X128
    ///      - (else leave at zero — convention)
    ///   7. info.liquidityGross = liquidityGrossAfter
    ///   8. If upper tick:  info.liquidityNet -= liquidityDelta
    ///      If lower tick:  info.liquidityNet += liquidityDelta
    ///   9. Store back to self[tick]
    ///
    /// @param self The mapping of tick → Info
    /// @param tick The tick being updated
    /// @param tickCurrent The current tick of the pool
    /// @param liquidityDelta The signed change in liquidity
    /// @param feeGrowthGlobal0X128 Global fee growth for token0
    /// @param feeGrowthGlobal1X128 Global fee growth for token1
    /// @param upper True if this is the upper tick, false if lower
    /// @param maxLiquidity The max liquidity per tick for this pool's tick spacing
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice-versa
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        // TODO: Implement the update logic described above
    }

    /// @notice Transitions a tick during a swap (crosses the tick)
    /// @dev LOGIC:
    ///   When the price crosses a tick during a swap, we must:
    ///   1. Flip the feeGrowthOutside values:
    ///      info.feeGrowthOutside0X128 = feeGrowthGlobal0X128 - info.feeGrowthOutside0X128
    ///      info.feeGrowthOutside1X128 = feeGrowthGlobal1X128 - info.feeGrowthOutside1X128
    ///   (This is because "outside" is relative to the current tick — when we cross,
    ///    what was "outside" becomes "inside" and vice versa)
    ///
    ///   2. Return info.liquidityNet (the net liquidity change to apply)
    ///
    /// @return liquidityNet The net liquidity change when this tick is crossed
    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal returns (int128 liquidityNet) {
        // TODO: Implement the crossing logic
        // NOTE: All subtractions must be unchecked (intentional overflow)
    }

    /// @notice Clears tick data (called when a tick's liquidityGross reaches 0)
    /// @dev Just delete self[tick]
    function clear(mapping(int24 => Tick.Info) storage self, int24 tick) internal {
        // TODO: delete self[tick]
    }
}
