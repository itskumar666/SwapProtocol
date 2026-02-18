// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {BeforeSwapDelta} from "../types/BeforeSwapDelta.sol";

/// @dev Param structs are defined independently to avoid circular imports
struct ModifyLiquidityParams {
    int24 tickLower;
    int24 tickUpper;
    int256 liquidityDelta;
    bytes32 salt;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

/// @title IHooks — the interface every hooks contract must implement
/// @notice PoolManager calls these at specific lifecycle points
/// @dev Address of a hooks contract encodes which hooks are active via bitmask in the leading bits
interface IHooks {
    // ─── Pool Lifecycle ────────────────────────────────────────

    /// @notice Called before pool initialization
    /// @param sender The msg.sender to PoolManager
    /// @param key The pool being initialized
    /// @param sqrtPriceX96 The initial sqrt price
    /// @param hookData Arbitrary data passed through by the caller
    /// @return bytes4 The function selector (IHooks.beforeInitialize.selector)
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        returns (bytes4);

    /// @notice Called after pool initialization
    /// @return bytes4 The function selector
    function afterInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24 tick,
        bytes calldata hookData
    ) external returns (bytes4);

    // ─── Liquidity ─────────────────────────────────────────────

    /// @notice Called before modifyLiquidity (add or remove)
    /// @return bytes4 The function selector
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice Called before removing liquidity
    /// @return bytes4 The function selector
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice Called after modifyLiquidity (add)
    /// @return bytes4 The function selector
    /// @return BalanceDelta Hook's own balance delta (for fee-on-add scenarios)
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    /// @notice Called after removing liquidity
    /// @return bytes4 The function selector
    /// @return BalanceDelta Hook's own balance delta
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    // ─── Swap ──────────────────────────────────────────────────

    /// @notice Called before a swap
    /// @return bytes4 The function selector
    /// @return BeforeSwapDelta Specified/unspecified deltas from the hook
    /// @return uint24 Optional LP fee override (only if BEFORE_SWAP_RETURNS_DELTA flag is set)
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4, BeforeSwapDelta, uint24);

    /// @notice Called after a swap
    /// @return bytes4 The function selector
    /// @return int128 Hook's unspecified currency delta
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128);

    // ─── Donate ────────────────────────────────────────────────

    /// @notice Called before donate
    /// @return bytes4 The function selector
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice Called after donate
    /// @return bytes4 The function selector
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);
}
