// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {PoolManager} from "../src/PoolManager.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IHooks} from "../src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "../src/types/Currency.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../src/types/BalanceDelta.sol";
import {TickMath} from "../src/libraries/TickMath.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {PoolSwapTest} from "./utils/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "./utils/PoolModifyLiquidityTest.sol";

/// @title PoolManagerTest — comprehensive test suite
/// @notice Tests for initialization, liquidity, swaps, settlement, protocol fees
contract PoolManagerTest is Test {
    PoolManager manager;
    MockERC20 token0;
    MockERC20 token1;
    PoolSwapTest swapRouter;
    PoolModifyLiquidityTest liquidityRouter;

    PoolKey poolKey;

    // Common test amounts
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // sqrt(1) * 2^96 — price = 1.0
    uint160 constant SQRT_PRICE_1_2 = 56022770974786139918731938227; // sqrt(0.5) * 2^96
    uint160 constant SQRT_PRICE_2_1 = 112045541949572279837463876454; // sqrt(2) * 2^96
    uint160 constant SQRT_PRICE_1_4 = 39614081257132168796771975168; // sqrt(0.25) * 2^96
    uint160 constant SQRT_PRICE_4_1 = 158456325028528675187087900672; // sqrt(4) * 2^96

    function setUp() public {
        // 1. Deploy PoolManager with this test contract as owner
        manager = new PoolManager(address(this));

        // 2. Deploy mock tokens
        token0 = new MockERC20("Token0", "TK0", 18);
        token1 = new MockERC20("Token1", "TK1", 18);

        // 3. Sort tokens — currency0 < currency1 (by address)
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }

        // 4. Deploy test routers
        swapRouter = new PoolSwapTest(IPoolManager(address(manager)));
        liquidityRouter = new PoolModifyLiquidityTest(IPoolManager(address(manager)));

        // 5. Mint tokens and approve routers
        token0.mint(address(this), 1000 ether);
        token1.mint(address(this), 1000 ether);
        token0.approve(address(swapRouter), type(uint256).max);
        token1.approve(address(swapRouter), type(uint256).max);
        token0.approve(address(liquidityRouter), type(uint256).max);
        token1.approve(address(liquidityRouter), type(uint256).max);

        // 6. Create default pool key (3000 = 0.3% fee, 60 tick spacing, no hooks)
        poolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
    }

    // ═══════════════════════════════════════════════════════════
    //                    INITIALIZATION TESTS
    // ═══════════════════════════════════════════════════════════

    function test_initialize_succeeds() public {
        // TODO: Initialize pool at SQRT_PRICE_1_1
        // VERIFY:
        //   - Returns tick == 0
        //   - Pool slot0 has correct sqrtPriceX96
        //   - Cannot initialize again (should revert with PoolAlreadyInitialized)
    }

    function test_initialize_revertsWithCurrenciesOutOfOrder() public {
        // TODO: Create a PoolKey with currency0 > currency1 and expect revert
    }

    function test_initialize_revertsWithTickSpacingTooLarge() public {
        // TODO: Set tickSpacing > MAX_TICK_SPACING and expect revert
    }

    function test_initialize_revertsWithTickSpacingTooSmall() public {
        // TODO: Set tickSpacing to 0 and expect revert
    }

    // ═══════════════════════════════════════════════════════════
    //                    LIQUIDITY TESTS
    // ═══════════════════════════════════════════════════════════

    function test_addLiquidity_succeeds() public {
        // TODO:
        // 1. Initialize pool
        // 2. Add liquidity via liquidityRouter.modifyLiquidity()
        //    - tickLower: -120, tickUpper: 120, liquidityDelta: 1 ether
        // VERIFY:
        //   - Token balances decrease (transferred to pool)
        //   - Pool liquidity increases
    }

    function test_addLiquidity_belowRange() public {
        // TODO: Add liquidity below the current price
        // tickLower: -600, tickUpper: -120
        // VERIFY: Only token0 should be deposited (one-sided)
    }

    function test_addLiquidity_aboveRange() public {
        // TODO: Add liquidity above the current price
        // tickLower: 120, tickUpper: 600
        // VERIFY: Only token1 should be deposited (one-sided)
    }

    function test_removeLiquidity_succeeds() public {
        // TODO:
        // 1. Initialize and add liquidity
        // 2. Remove liquidity (negative liquidityDelta)
        // VERIFY: Tokens returned to user
    }

    // ═══════════════════════════════════════════════════════════
    //                      SWAP TESTS
    // ═══════════════════════════════════════════════════════════

    function test_swap_exactInputZeroForOne() public {
        // TODO:
        // 1. Initialize pool, add liquidity
        // 2. Swap: zeroForOne=true, amountSpecified=1 ether (positive = exact input)
        //    sqrtPriceLimitX96 = TickMath.MIN_SQRT_PRICE + 1
        // VERIFY:
        //   - Caller's token0 decreases
        //   - Caller's token1 increases
        //   - Pool price moves down (sqrtPrice decreases)
    }

    function test_swap_exactInputOneForZero() public {
        // TODO: Same but zeroForOne=false, limit = MAX_SQRT_PRICE - 1
    }

    function test_swap_exactOutputZeroForOne() public {
        // TODO:
        // amountSpecified = -0.5 ether (negative = exact output)
        // VERIFY: Caller receives exactly 0.5 ether of token1
    }

    function test_swap_revertsWithZeroAmount() public {
        // TODO: amountSpecified = 0 should revert SwapAmountCannotBeZero
    }

    function test_swap_revertsWhenPoolNotInitialized() public {
        // TODO: Swap on uninitialized pool should revert PoolNotInitialized
    }

    // ═══════════════════════════════════════════════════════════
    //                   FLASH ACCOUNTING TESTS
    // ═══════════════════════════════════════════════════════════

    function test_unlock_revertsWhenNotSettled() public {
        // TODO: Perform a swap but DON'T settle in the callback
        // VERIFY: Reverts with CurrencyNotSettled
    }

    function test_settle_withNativeETH() public {
        // TODO: Test settling with native ETH (currency = address(0))
    }

    function test_mintAndBurn_claims() public {
        // TODO:
        // 1. Do a swap that gives output
        // 2. Instead of take(), use mint() to get ERC6909 claims
        // 3. Check ERC6909 balance
        // 4. Later, use burn() to settle a debt with claims
    }

    // ═══════════════════════════════════════════════════════════
    //                    DONATE TESTS
    // ═══════════════════════════════════════════════════════════

    function test_donate_succeeds() public {
        // TODO:
        // 1. Initialize pool, add liquidity
        // 2. Donate amount0=0.1 ether, amount1=0.1 ether
        // VERIFY: Fee growth accumulators increase
    }

    function test_donate_revertsWithNoLiquidity() public {
        // TODO: Initialize pool but DON'T add liquidity
        // Donate should revert NoLiquidityToReceiveFees
    }

    // ═══════════════════════════════════════════════════════════
    //                   PROTOCOL FEE TESTS
    // ═══════════════════════════════════════════════════════════

    function test_setProtocolFeeController() public {
        // TODO: Set protocol fee controller as owner
        // VERIFY: protocolFeeController is updated
    }

    function test_collectProtocolFees() public {
        // TODO:
        // 1. Set up a protocol fee controller
        // 2. Set protocol fee on a pool
        // 3. Perform swaps to accumulate protocol fees
        // 4. Collect fees
        // VERIFY: Correct amount transferred to the collector
    }

    // ═══════════════════════════════════════════════════════════
    //                    ERC6909 TESTS
    // ═══════════════════════════════════════════════════════════

    function test_erc6909_transfer() public {
        // TODO: After minting claims, test transfer between accounts
    }

    function test_erc6909_approval() public {
        // TODO: Test approve + transferFrom flow
    }

    // ═══════════════════════════════════════════════════════════
    //                    MATH LIBRARY TESTS
    // ═══════════════════════════════════════════════════════════

    function test_tickMath_boundaries() public pure {
        // TODO: Test that:
        //   getSqrtPriceAtTick(MIN_TICK) == MIN_SQRT_PRICE
        //   getSqrtPriceAtTick(MAX_TICK) ≈ MAX_SQRT_PRICE
        //   getTickAtSqrtPrice(MIN_SQRT_PRICE) == MIN_TICK
        //   getTickAtSqrtPrice(MAX_SQRT_PRICE - 1) == MAX_TICK - 1
    }

    function test_tickMath_roundTrip() public pure {
        // TODO: For various ticks, verify:
        //   getTickAtSqrtPrice(getSqrtPriceAtTick(tick)) == tick
    }

    function test_fullMath_mulDiv() public pure {
        // TODO: Test mulDiv with large numbers that would overflow uint256
    }
}
