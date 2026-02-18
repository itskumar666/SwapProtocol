// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "../types/Currency.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {PoolId} from "../types/PoolId.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {IHooks, ModifyLiquidityParams, SwapParams} from "./IHooks.sol";
import {IProtocolFeeController} from "./IProtocolFeeController.sol";
import {IERC6909Claims} from "./IERC6909Claims.sol";

/// @title IPoolManager — the full interface for the V4 singleton
/// @notice Manages all pools, flash accounting, hooks, and protocol fees
interface IPoolManager is IERC6909Claims {
    // ═══════════════════════════════════════════════════════════
    //                         ERRORS
    // ═══════════════════════════════════════════════════════════

    error CurrenciesOutOfOrderOrEqual(Currency currency0, Currency currency1);
    error CurrencyNotSettled();
    error PoolAlreadyInitialized();
    error PoolNotInitialized();
    error TickSpacingTooLarge(int24 tickSpacing);
    error TickSpacingTooSmall(int24 tickSpacing);
    error SwapAmountCannotBeZero();
    error NonzeroNativeValue();
    error ManagerLocked();
    error AlreadyUnlocked();
    error InvalidCaller();
    error UnauthorizedDynamicLPFeeUpdate();
    error ProtocolFeeTooLarge(uint24 fee);

    // ═══════════════════════════════════════════════════════════
    //                         EVENTS
    // ═══════════════════════════════════════════════════════════

    event Initialize(
        PoolId indexed id,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        IHooks hooks,
        uint160 sqrtPriceX96,
        int24 tick
    );

    event ModifyLiquidity(
        PoolId indexed id, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta, bytes32 salt
    );

    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee
    );

    event Donate(PoolId indexed id, address indexed sender, uint256 amount0, uint256 amount1);

    event ProtocolFeeControllerUpdated(address indexed protocolFeeController);

    event ProtocolFeeUpdated(PoolId indexed id, uint24 protocolFee);

    // ═══════════════════════════════════════════════════════════
    //                     CORE FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Acquires the lock for flash accounting, calls unlockCallback on msg.sender
    /// @param data Arbitrary data forwarded to the callback
    /// @return Whatever the callback returns
    function unlock(bytes calldata data) external returns (bytes memory);

    /// @notice Initializes a new pool
    /// @param key The pool key (currencies must be sorted, currency0 < currency1)
    /// @param sqrtPriceX96 The initial sqrt(price) in Q64.96
    /// @param hookData Data forwarded to hooks
    /// @return tick The initial tick corresponding to sqrtPriceX96
    function initialize(PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        returns (int24 tick);

    /// @notice Adds or removes concentrated liquidity
    /// @dev Can only be called inside an unlock callback
    function modifyLiquidity(PoolKey calldata key, ModifyLiquidityParams calldata params, bytes calldata hookData)
        external
        returns (BalanceDelta callerDelta, BalanceDelta feesAccrued);

    /// @notice Executes a swap against a pool
    /// @dev Can only be called inside an unlock callback
    function swap(PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (BalanceDelta swapDelta);

    /// @notice Donates tokens to in-range LPs (adds to fee accumulators without getting liquidity)
    /// @dev Can only be called inside an unlock callback
    function donate(PoolKey calldata key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        returns (BalanceDelta delta);

    // ═══════════════════════════════════════════════════════════
    //                  SETTLEMENT FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Settle a currency debt by transferring tokens to PoolManager
    /// @return The amount that was settled (credited to the caller's delta)
    function settle() external payable returns (uint256);

    /// @notice Settle using ERC6909 claim tokens instead of real transfers
    /// @return The amount settled
    function settleFor(address recipient) external payable returns (uint256);

    /// @notice Take tokens from PoolManager (creates a debt for the caller)
    function take(Currency currency, address to, uint256 amount) external;

    /// @notice Mint ERC6909 claim tokens instead of taking real tokens
    function mint(address to, uint256 id, uint256 amount) external;

    /// @notice Burn ERC6909 claim tokens (settles debt using claims)
    function burn(address from, uint256 id, uint256 amount) external;

    /// @notice Syncs the contract's tracked reserve for a currency before a settle
    /// @dev Must be called before transferring tokens for settlement when using transfer-then-settle pattern
    function sync(Currency currency) external;

    // ═══════════════════════════════════════════════════════════
    //                    PROTOCOL FEE
    // ═══════════════════════════════════════════════════════════

    /// @notice Sets the protocol fee for a specific pool (called by fee controller)
    function setProtocolFee(PoolKey calldata key, uint24 newProtocolFee) external;

    /// @notice Collects accumulated protocol fees
    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        returns (uint256 amountCollected);

    /// @notice Updates the dynamic LP fee for a pool (only callable by the pool's hooks contract)
    function updateDynamicLPFee(PoolKey calldata key, uint24 newDynamicLPFee) external;

    // ═══════════════════════════════════════════════════════════
    //                       VIEWS
    // ═══════════════════════════════════════════════════════════

    /// @notice Checks if the manager is currently unlocked
    function isUnlocked() external view returns (bool);

    /// @notice Returns the current reserves tracked for a currency
    function reservesOf(Currency currency) external view returns (uint256);
}
