// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Tick} from "./Tick.sol";
import {TickBitmap} from "./TickBitmap.sol";
import {Position} from "./Position.sol";
import {SafeCast} from "./SafeCast.sol";
import {FullMath} from "./FullMath.sol";
import {FixedPoint128} from "./FixedPoint128.sol";
import {TickMath} from "./TickMath.sol";
import {SqrtPriceMath} from "./SqrtPriceMath.sol";
import {SwapMath} from "./SwapMath.sol";
import {LiquidityMath} from "./LiquidityMath.sol";
import {BalanceDelta, toBalanceDelta} from "../types/BalanceDelta.sol";
import {Slot0, Slot0Library} from "../types/Slot0.sol";

/// @title Pool — the core pool state machine library
/// @notice Manages all state transitions for a single pool
/// @dev Used as a library by PoolManager — each pool is a Pool.State struct in a mapping
library Pool {
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.State);
    using SafeCast for int256;
    using SafeCast for uint256;

    // ═══════════════════════════════════════════════════════════
    //                         ERRORS
    // ═══════════════════════════════════════════════════════════

    error PoolNotInitialized();
    error PoolAlreadyInitialized();
    error PriceLimitAlreadyExceeded(uint160 sqrtPriceCurrentX96, uint160 sqrtPriceLimitX96);
    error PriceLimitOutOfBounds(uint160 sqrtPriceLimitX96);
    error NoLiquidityToReceiveFees();
    error InvalidFeeForExactOut();

    // ═══════════════════════════════════════════════════════════
    //                     POOL STATE
    // ═══════════════════════════════════════════════════════════

    /// @notice The complete state of a pool
    struct State {
        /// @dev Packed: sqrtPriceX96 (160) | tick (24) | protocolFee (24) | lpFee (24)
        Slot0 slot0;
        /// @dev Fee growth accumulator for token0 (Q128.128)
        uint256 feeGrowthGlobal0X128;
        /// @dev Fee growth accumulator for token1 (Q128.128)
        uint256 feeGrowthGlobal1X128;
        /// @dev Current in-range liquidity available for swaps
        uint128 liquidity;
        /// @dev Mapping of tick index → tick state
        mapping(int24 => Tick.Info) ticks;
        /// @dev Bitmap of initialized ticks (1 bit per tick, compressed by tickSpacing)
        mapping(int16 => uint256) tickBitmap;
        /// @dev Mapping of position key → position state
        mapping(bytes32 => Position.State) positions;
    }

    // ═══════════════════════════════════════════════════════════
    //                  SWAP INTERNAL CACHE
    // ═══════════════════════════════════════════════════════════

    /// @dev Transient data used only during a swap execution (not stored)
    struct SwapCache {
        /// @dev The protocol fee for the input token
        uint8 protocolFee;
        /// @dev The LP fee (after protocol fee deduction if applicable)
        uint24 lpFeeOverride;
        /// @dev Current in-range liquidity (cached to avoid repeated SLOADs)
        uint128 liquidityStart;
        /// @dev The tick spacing of this pool
        int24 tickSpacing;
    }

    /// @dev Step computation cache — represents one iteration of the swap loop
    struct StepComputations {
        /// @dev The sqrt price at the beginning of this step
        uint160 sqrtPriceStartX96;
        /// @dev The next tick to swap to (from bitmap lookup)
        int24 tickNext;
        /// @dev Whether tickNext is initialized (has liquidity)
        bool initialized;
        /// @dev The sqrt price of the next tick boundary
        uint160 sqrtPriceNextX96;
        /// @dev How much was consumed as input in this step
        uint256 amountIn;
        /// @dev How much was produced as output in this step
        uint256 amountOut;
        /// @dev The fee generated in this step
        uint256 feeAmount;
    }

    // ═══════════════════════════════════════════════════════════
    //                    MODIFY LIQUIDITY PARAMS
    // ═══════════════════════════════════════════════════════════

    struct ModifyLiquidityParams {
        /// @dev The address that owns the position
        address owner;
        /// @dev The lower tick of the position
        int24 tickLower;
        /// @dev The upper tick of the position
        int24 tickUpper;
        /// @dev The signed liquidity delta (+add, -remove)
        int128 liquidityDelta;
        /// @dev The current tick of the pool (cached)
        int24 tick;
        /// @dev The pool's tick spacing
        int24 tickSpacing;
        /// @dev Salt for position uniqueness
        bytes32 salt;
    }

    struct ModifyLiquidityState {
        bool flippedLower;
        bool flippedUpper;
        uint128 maxLiquidityPerTick;
    }

    // ═══════════════════════════════════════════════════════════
    //                      FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Initializes a pool with the given sqrt price
    /// @dev CHECKS:
    ///   1. Pool must NOT be already initialized
    ///      - slot0.sqrtPriceX96() != 0 means already initialized → revert PoolAlreadyInitialized
    ///   2. sqrtPriceX96 must be within [MIN_SQRT_PRICE, MAX_SQRT_PRICE)
    ///
    /// LOGIC:
    ///   1. Compute tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96)
    ///   2. Pack slot0 with sqrtPriceX96, tick, protocolFee, and lpFee
    ///   3. Store slot0 into self.slot0
    ///   4. Return tick
    ///
    /// @param self The pool state
    /// @param sqrtPriceX96 The initial sqrt price
    /// @param protocolFee The initial protocol fee (from controller)
    /// @param lpFee The LP fee (static or dynamic initial)
    /// @return tick The initial tick
    function initialize(State storage self, uint160 sqrtPriceX96, uint24 protocolFee, uint24 lpFee)
        internal
        returns (int24 tick)
    {
        // TODO: Implement
    }

    /// @notice Modifies a position's liquidity (add or remove)
    /// @dev This is the most complex function. LOGIC:
    ///
    ///   PHASE 1 — Fee Growth Snapshot:
    ///     1. Get feeGrowthInside0X128, feeGrowthInside1X128 from Tick.getFeeGrowthInside()
    ///        using tickLower, tickUpper, currentTick, and the global fee growth accumulators
    ///
    ///   PHASE 2 — Update Position:
    ///     2. Calculate positionKey = Position.calculatePositionKey(owner, tickLower, tickUpper, salt)
    ///     3. Call Position.update(positions, positionKey, liquidityDelta, feeGrowthInside0, feeGrowthInside1)
    ///        → returns (feesOwed0, feesOwed1)
    ///
    ///   PHASE 3 — Update Ticks (only if liquidityDelta != 0):
    ///     4. If liquidityDelta != 0:
    ///        a. Update lower tick: flippedLower = Tick.update(ticks, tickLower, tick, liquidityDelta, feeGrowth0, feeGrowth1, false, maxLiqPerTick)
    ///        b. Update upper tick: flippedUpper = Tick.update(ticks, tickUpper, tick, liquidityDelta, feeGrowth0, feeGrowth1, true, maxLiqPerTick)
    ///        c. If flippedLower → TickBitmap.flipTick(tickBitmap, tickLower, tickSpacing)
    ///        d. If flippedUpper → TickBitmap.flipTick(tickBitmap, tickUpper, tickSpacing)
    ///
    ///   PHASE 4 — Update Pool Liquidity:
    ///     5. If the current tick is inside the position range [tickLower, tickUpper):
    ///        self.liquidity = LiquidityMath.addDelta(self.liquidity, liquidityDelta)
    ///
    ///   PHASE 5 — Compute Token Deltas:
    ///     6. Calculate amount0 and amount1 needed/returned via SqrtPriceMath:
    ///        - If tick < tickLower (below range): only token0 is needed
    ///            amount0 = SqrtPriceMath.getAmount0Delta(sqrtPriceLower, sqrtPriceUpper, liquidityDelta)
    ///        - If tick >= tickUpper (above range): only token1 is needed
    ///            amount1 = SqrtPriceMath.getAmount1Delta(sqrtPriceLower, sqrtPriceUpper, liquidityDelta)
    ///        - If tickLower <= tick < tickUpper (in range): both tokens
    ///            amount0 = SqrtPriceMath.getAmount0Delta(sqrtPriceCurrent, sqrtPriceUpper, liquidityDelta)
    ///            amount1 = SqrtPriceMath.getAmount1Delta(sqrtPriceLower, sqrtPriceCurrent, liquidityDelta)
    ///
    ///   PHASE 6 — Pack Result:
    ///     7. callerDelta = toBalanceDelta(amount0, amount1)
    ///        - Positive = caller owes tokens to pool, Negative = pool owes tokens to caller
    ///     8. feeDelta = toBalanceDelta(feesOwed0, feesOwed1)
    ///        - Fees always go to the caller (negative delta = pool pays out)
    ///
    ///   PHASE 7 — Cleanup (if removing all liquidity and tick flipped):
    ///     9. If liquidityDelta < 0 AND flippedLower → Tick.clear(ticks, tickLower)
    ///     10. If liquidityDelta < 0 AND flippedUpper → Tick.clear(ticks, tickUpper)
    ///
    /// @return callerDelta The token amounts the caller must pay or receives
    /// @return feeDelta The fees owed to the position owner
    function modifyLiquidity(State storage self, ModifyLiquidityParams memory params)
        internal
        returns (BalanceDelta callerDelta, BalanceDelta feeDelta)
    {
        // TODO: Implement all 7 phases described above
    }

    /// @notice Executes a swap against the pool
    /// @dev The swap iterates across tick boundaries until the amount is exhausted or price limit is hit.
    ///
    /// CHECKS:
    ///   1. amountSpecified != 0 → else nothing to swap
    ///   2. Pool must be initialized (slot0.sqrtPriceX96() != 0)
    ///   3. Price limit validation:
    ///      - zeroForOne: sqrtPriceLimitX96 < sqrtPriceCurrent AND sqrtPriceLimitX96 > MIN_SQRT_PRICE
    ///      - !zeroForOne: sqrtPriceLimitX96 > sqrtPriceCurrent AND sqrtPriceLimitX96 < MAX_SQRT_PRICE
    ///
    /// CACHE SETUP:
    ///   - swapFee = slot0.lpFee() (or override if dynamic)
    ///   - protocolFee = extract from slot0.protocolFee() based on direction
    ///   - If protocolFee > 0: swapFee = protocolFee + lpFee * (1 - protocolFee/1e6)
    ///     (protocol fee is taken first, then LP fee on remainder)
    ///
    /// SWAP LOOP:
    ///   while (amountRemaining != 0 AND sqrtPrice != sqrtPriceLimit):
    ///     1. step.sqrtPriceStartX96 = current sqrt price
    ///     2. (step.tickNext, step.initialized) = tickBitmap.nextInitializedTickWithinOneWord(
    ///            currentTick, tickSpacing, zeroForOne)
    ///     3. Clamp tickNext to [MIN_TICK, MAX_TICK]
    ///     4. step.sqrtPriceNextX96 = TickMath.getSqrtPriceAtTick(step.tickNext)
    ///     5. Determine target price = min/max of (sqrtPriceNext, sqrtPriceLimit) based on direction
    ///     6. (sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) =
    ///            SwapMath.computeSwapStep(sqrtPriceCurrent, target, liquidity, amountRemaining, swapFee)
    ///
    ///     7. Update amountRemaining:
    ///        - exactIn: amountRemaining -= (amountIn + feeAmount)  [as int256]
    ///        - exactOut: amountRemaining += amountOut  [as int256]
    ///
    ///     8. Protocol fee accounting:
    ///        If protocolFee > 0:
    ///          protocolFeeAmount = feeAmount * protocolFee / swapFee
    ///          feeAmount -= protocolFeeAmount
    ///          (accumulate into result's protocol fees)
    ///
    ///     9. Fee growth accumulation:
    ///        If liquidity > 0:
    ///          feeGrowthGlobalX128 += FullMath.mulDiv(feeAmount, FixedPoint128.Q128, liquidity)
    ///        (for the input token's fee growth accumulator)
    ///
    ///     10. Tick crossing:
    ///         If sqrtPriceX96 == step.sqrtPriceNextX96 (reached tick boundary):
    ///           a. If step.initialized:
    ///              liquidityNet = Tick.cross(ticks, step.tickNext, feeGrowth0, feeGrowth1)
    ///              If zeroForOne: liquidityNet = -liquidityNet (direction flip)
    ///              liquidity = LiquidityMath.addDelta(liquidity, liquidityNet)
    ///           b. Update tick:
    ///              zeroForOne: tick = step.tickNext - 1
    ///              !zeroForOne: tick = step.tickNext
    ///         Else (didn't reach boundary):
    ///           tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96)
    ///
    /// POST-LOOP:
    ///   1. Update slot0 with new sqrtPriceX96 and tick
    ///   2. If tick changed: update self.liquidity if it differs from liquidityStart
    ///   3. Compute result:
    ///      - exactIn + zeroForOne: delta = (amountSpecified - amountRemaining, amountCalculated)
    ///      - exactIn + !zeroForOne: delta = (amountCalculated, amountSpecified - amountRemaining)
    ///      - exactOut + zeroForOne: delta = (amountCalculated, amountSpecified - amountRemaining)
    ///      - etc.
    ///
    /// @param self The pool state
    /// @param params Swap parameters
    /// @return result BalanceDelta — (amount0, amount1) from the pool's perspective
    ///         Positive = pool receives, Negative = pool sends
    /// @return swapFee The effective swap fee used
    function swap(State storage self, SwapParams memory params)
        internal
        returns (BalanceDelta result, uint256 swapFee)
    {
        // TODO: Implement the full swap loop as described above
    }

    /// @notice Donates tokens to in-range liquidity providers
    /// @dev CHECKS:
    ///   1. Pool must be initialized
    ///   2. self.liquidity > 0 → revert NoLiquidityToReceiveFees
    ///
    /// LOGIC:
    ///   1. If amount0 > 0:
    ///      feeGrowthGlobal0X128 += FullMath.mulDiv(amount0, FixedPoint128.Q128, self.liquidity)
    ///   2. If amount1 > 0:
    ///      feeGrowthGlobal1X128 += FullMath.mulDiv(amount1, FixedPoint128.Q128, self.liquidity)
    ///   3. Return toBalanceDelta(amount0, amount1)
    ///
    /// @return delta The amounts donated (positive = caller owes)
    function donate(State storage self, uint256 amount0, uint256 amount1) internal returns (BalanceDelta delta) {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                      SWAP PARAMS
    // ═══════════════════════════════════════════════════════════

    struct SwapParams {
        int24 tickSpacing;
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
        uint24 lpFeeOverride;
    }
}
