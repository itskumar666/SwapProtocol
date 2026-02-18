// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import {Hooks} from "./libraries/Hooks.sol";
import {Pool} from "./libraries/Pool.sol";
import {SafeCast} from "./libraries/SafeCast.sol";
import {Tick} from "./libraries/Tick.sol";
import {TickMath} from "./libraries/TickMath.sol";
import {Position} from "./libraries/Position.sol";
import {LPFeeLibrary} from "./libraries/LPFeeLibrary.sol";
import {ProtocolFeeLibrary} from "./libraries/ProtocolFeeLibrary.sol";
import {Currency, CurrencyLibrary} from "./types/Currency.sol";
import {PoolKey} from "./types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "./types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary, toBalanceDelta} from "./types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "./types/BeforeSwapDelta.sol";
import {Slot0, Slot0Library} from "./types/Slot0.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {IHooks, ModifyLiquidityParams, SwapParams} from "./interfaces/IHooks.sol";
import {IUnlockCallback} from "./interfaces/IUnlockCallback.sol";
import {IProtocolFeeController} from "./interfaces/IProtocolFeeController.sol";
import {IERC6909Claims} from "./interfaces/IERC6909Claims.sol";
import {ERC6909} from "./ERC6909.sol";
import {Extsload} from "./Extsload.sol";
import {Exttload} from "./Exttload.sol";
import {ProtocolFees} from "./ProtocolFees.sol";

import {Ownable} from "./Ownable.sol";

/// @title PoolManager — the V4 singleton that manages all pools
/// @notice One contract to rule them all. All pool state, flash accounting,
///         hooks orchestration, and settlement happen here.
///
/// ARCHITECTURE:
///   PoolManager inherits:
///     - ERC6909: multi-token claims (surplus balances)
///     - Extsload: external storage reads
///     - Exttload: external transient storage reads
///     - ProtocolFees: protocol fee management (which inherits Ownable)
///
///   Key patterns:
///     - Flash Accounting: no tokens move until settlement. All operations produce deltas.
///     - Transient Storage (EIP-1153): currency deltas stored in TSTORE/TLOAD, cleared per tx.
///     - Singleton: ALL pools live in one contract. No factory → pool-per-contract.
///     - Hooks: called at lifecycle points, validated by address bits.
///
contract PoolManager is IPoolManager, ERC6909, Extsload, Exttload, ProtocolFees {
    using Pool for Pool.State;
    using Hooks for IHooks;
    using SafeCast for int256;
    using SafeCast for uint256;
    using CurrencyLibrary for Currency;
    using LPFeeLibrary for uint24;
    using ProtocolFeeLibrary for uint24;

    // ═══════════════════════════════════════════════════════════
    //                       CONSTANTS
    // ═══════════════════════════════════════════════════════════

    /// @notice Maximum tick spacing for any pool
    int24 public constant MAX_TICK_SPACING = 16383;

    /// @notice Minimum tick spacing for any pool
    int24 public constant MIN_TICK_SPACING = 1;

    // ═══════════════════════════════════════════════════════════
    //               TRANSIENT STORAGE SLOTS
    // ═══════════════════════════════════════════════════════════
    //
    // These are constants used as base slots for TSTORE/TLOAD.
    // Transient storage is cleared after each transaction.
    //

    /// @dev Slot for the unlock state. 0 = locked, 1 = unlocked.
    /// LAYOUT: tstore(IS_UNLOCKED_SLOT, value)
    bytes32 internal constant IS_UNLOCKED_SLOT = bytes32(uint256(0));

    /// @dev Slot for tracking the number of nonzero currency deltas.
    /// Used to enforce all deltas are settled before unlock returns.
    /// LAYOUT: tstore(NONZERO_DELTA_COUNT_SLOT, count)
    bytes32 internal constant NONZERO_DELTA_COUNT_SLOT = bytes32(uint256(1));

    /// @dev Base slot for per-currency reserves.
    /// Actual slot = keccak256(abi.encode(currency, RESERVES_OF_SLOT))
    /// Used for sync() to snapshot balances before settlement.
    bytes32 internal constant RESERVES_OF_SLOT = bytes32(uint256(2));

    /// @dev Base slot for currency deltas.
    /// Actual slot = keccak256(abi.encodePacked(caller, currency))
    /// Stores int256 delta per (caller, currency) pair.
    // (No constant needed — computed on the fly)

    // ═══════════════════════════════════════════════════════════
    //                    PERSISTENT STORAGE
    // ═══════════════════════════════════════════════════════════

    /// @notice All pool states, keyed by PoolId (= keccak256 of PoolKey)
    mapping(bytes32 => Pool.State) internal _pools;

    // ═══════════════════════════════════════════════════════════
    //                      CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════

    /// @param initialOwner The initial owner (can set protocol fee controller)
    constructor(address initialOwner) Ownable(initialOwner) {}

    // ═══════════════════════════════════════════════════════════
    //                       MODIFIERS
    // ═══════════════════════════════════════════════════════════

    /// @notice Ensures the PoolManager is currently unlocked (inside a callback)
    /// @dev LOGIC: Read IS_UNLOCKED_SLOT from transient storage
    ///   CHECK: value == 1 → else revert ManagerLocked
    modifier onlyWhenUnlocked() {
        // TODO: Implement
        // assembly { if iszero(tload(IS_UNLOCKED_SLOT)) { revert(...) } }
        _;
    }

    // ═══════════════════════════════════════════════════════════
    //                      UNLOCK (FLASH ACCOUNTING)
    // ═══════════════════════════════════════════════════════════

    /// @notice Acquires the lock, calls the caller's unlockCallback, then verifies all deltas are settled
    /// @dev THIS IS THE ENTRY POINT for all pool operations.
    ///
    /// LOGIC:
    ///   1. CHECK: not already unlocked → revert AlreadyUnlocked
    ///      - Read IS_UNLOCKED_SLOT from tload. Must be 0.
    ///   2. Set IS_UNLOCKED_SLOT = 1 (tstore)
    ///   3. Call IUnlockCallback(msg.sender).unlockCallback(data)
    ///      - The caller performs swaps, modifyLiquidity, etc. inside the callback
    ///      - Each operation creates currency deltas in transient storage
    ///      - The caller must settle all deltas (via settle/take/mint/burn)
    ///   4. CHECK: nonzeroDeltaCount == 0 → revert CurrencyNotSettled
    ///      - Read NONZERO_DELTA_COUNT_SLOT from tload
    ///      - Must be 0 (all debts paid, all credits taken)
    ///   5. Set IS_UNLOCKED_SLOT = 0 (tstore) — re-lock
    ///   6. Return the callback's return data
    ///
    function unlock(bytes calldata data) external override returns (bytes memory result) {
        // TODO: Implement the flash accounting entry point
    }

    // ═══════════════════════════════════════════════════════════
    //                      INITIALIZE
    // ═══════════════════════════════════════════════════════════

    /// @notice Initializes a new pool
    /// @dev CHECKS:
    ///   1. key.currency0 < key.currency1 → revert CurrenciesOutOfOrderOrEqual
    ///      (currencies must be sorted, and cannot be the same)
    ///   2. key.tickSpacing > 0 AND key.tickSpacing <= MAX_TICK_SPACING
    ///      → revert TickSpacingTooSmall or TickSpacingTooLarge
    ///   3. key.fee.isValid() → validates LP fee is within bounds
    ///   4. Hooks address validation (if hooks != address(0), flags must be consistent)
    ///
    /// LOGIC:
    ///   1. Call hooks.callBeforeInitialize(msg.sender, key, sqrtPriceX96, hookData)
    ///   2. Compute PoolId = key.toId()
    ///   3. Determine LP fee: if dynamic → 0 initially; else → key.fee
    ///   4. Fetch protocol fee from controller: _fetchProtocolFee(key)
    ///   5. Call _pools[id].initialize(sqrtPriceX96, protocolFee, lpFee)
    ///      → returns tick
    ///   6. Call hooks.callAfterInitialize(msg.sender, key, sqrtPriceX96, tick, hookData)
    ///   7. Emit Initialize event
    ///   8. Return tick
    function initialize(PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        override
        returns (int24 tick)
    {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                    MODIFY LIQUIDITY
    // ═══════════════════════════════════════════════════════════

    /// @notice Adds or removes concentrated liquidity
    /// @dev CHECKS:
    ///   1. onlyWhenUnlocked modifier
    ///   2. Tick validation via Tick.checkTicks(params.tickLower, params.tickUpper)
    ///
    /// LOGIC:
    ///   1. Determine if adding or removing:
    ///      - params.liquidityDelta > 0 → adding → call hooks.callBeforeAddLiquidity()
    ///      - params.liquidityDelta < 0 → removing → call hooks.callBeforeRemoveLiquidity()
    ///
    ///   2. Call pool.modifyLiquidity(Pool.ModifyLiquidityParams{
    ///        owner: msg.sender,
    ///        tickLower, tickUpper, liquidityDelta, tick, tickSpacing, salt
    ///      })
    ///      → returns (callerDelta, feeDelta)
    ///
    ///   3. Emit ModifyLiquidity event
    ///
    ///   4. After hooks:
    ///      - Adding → call hooks.callAfterAddLiquidity() → may return hookDelta
    ///      - Removing → call hooks.callAfterRemoveLiquidity() → may return hookDelta
    ///
    ///   5. Settle deltas in transient storage:
    ///      - _accountDelta(key.currency0, callerDelta.amount0(), msg.sender)
    ///      - _accountDelta(key.currency1, callerDelta.amount1(), msg.sender)
    ///      - If hookDelta != 0:
    ///        _accountDelta(key.currency0, hookDelta.amount0(), address(key.hooks))
    ///        _accountDelta(key.currency1, hookDelta.amount1(), address(key.hooks))
    ///
    ///   6. feesAccrued delta goes to the caller (negative = pool pays out fees)
    ///      - callerDelta includes feeDelta already subtracted
    function modifyLiquidity(PoolKey calldata key, ModifyLiquidityParams calldata params, bytes calldata hookData)
        external
        override
        onlyWhenUnlocked
        returns (BalanceDelta callerDelta, BalanceDelta feesAccrued)
    {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                         SWAP
    // ═══════════════════════════════════════════════════════════

    /// @notice Executes a swap
    /// @dev CHECKS:
    ///   1. onlyWhenUnlocked modifier
    ///   2. params.amountSpecified != 0 → revert SwapAmountCannotBeZero
    ///
    /// LOGIC:
    ///   1. Call hooks.callBeforeSwap(msg.sender, key, params, hookData)
    ///      → returns (beforeSwapDelta, lpFeeOverride)
    ///
    ///   2. Determine the effective LP fee:
    ///      - If dynamic fee pool AND hook returned override:
    ///        Use the overridden fee
    ///      - Else: use the pool's stored LP fee
    ///
    ///   3. Call pool.swap(Pool.SwapParams{
    ///        tickSpacing, zeroForOne, amountSpecified, sqrtPriceLimitX96, lpFeeOverride
    ///      })
    ///      → returns (swapDelta, swapFee)
    ///
    ///   4. Apply beforeSwapDelta adjustments:
    ///      - hookDeltaSpecified changes the specified currency delta
    ///      - hookDeltaUnspecified changes the unspecified currency delta
    ///
    ///   5. Call hooks.callAfterSwap(msg.sender, key, params, swapDelta, hookData)
    ///      → returns hookDeltaUnspecified
    ///
    ///   6. Settle deltas in transient storage:
    ///      - _accountDelta(key.currency0, swapDelta.amount0(), msg.sender)
    ///      - _accountDelta(key.currency1, swapDelta.amount1(), msg.sender)
    ///      - Account hook deltas to address(key.hooks) if nonzero
    ///
    ///   7. Emit Swap event with final values
    ///
    ///   8. Return the caller's swapDelta
    function swap(PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        override
        onlyWhenUnlocked
        returns (BalanceDelta swapDelta)
    {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                        DONATE
    // ═══════════════════════════════════════════════════════════

    /// @notice Donates to in-range LPs
    /// @dev CHECKS:
    ///   1. onlyWhenUnlocked modifier
    ///
    /// LOGIC:
    ///   1. Call hooks.callBeforeDonate(msg.sender, key, amount0, amount1, hookData)
    ///   2. Call pool.donate(amount0, amount1) → returns delta
    ///   3. Account deltas in transient storage
    ///   4. Call hooks.callAfterDonate(msg.sender, key, amount0, amount1, hookData)
    ///   5. Emit Donate event
    function donate(PoolKey calldata key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        override
        onlyWhenUnlocked
        returns (BalanceDelta delta)
    {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                    SETTLEMENT FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Syncs reserves before token transfer (for settle pattern)
    /// @dev LOGIC:
    ///   1. CHECK: currency must not be native (address(0)) → revert if so
    ///   2. Read current balance: currency.balanceOfSelf()
    ///   3. Store in transient reserves slot:
    ///      tstore(reserveSlot(currency), balance)
    ///   This allows settle() to compute how much was transferred by diffing.
    function sync(Currency currency) external onlyWhenUnlocked {
        // TODO: Implement
    }

    /// @notice Settles a currency debt by detecting the tokens transferred to PoolManager
    /// @dev LOGIC:
    ///   1. Determine amount settled:
    ///      - If native currency (ETH): amount = msg.value
    ///      - If ERC20: amount = currency.balanceOfSelf() - reservesOf(currency)
    ///        (diff between current balance and the synced reserve)
    ///   2. Apply delta: _accountDelta(currency, amount.toInt256(), msg.sender)
    ///      (positive delta = credit, reducing debt)
    ///   3. Return the amount settled
    function settle() external payable override onlyWhenUnlocked returns (uint256 paid) {
        // TODO: Implement
    }

    /// @notice Settles for a specific recipient (useful for routers settling on behalf of users)
    /// @dev Same as settle() but credits the delta to 'recipient' instead of msg.sender
    function settleFor(address recipient) external payable override onlyWhenUnlocked returns (uint256 paid) {
        // TODO: Implement
    }

    /// @notice Takes tokens from PoolManager
    /// @dev LOGIC:
    ///   1. _accountDelta(currency, -(amount.toInt256()), msg.sender)
    ///      (negative delta = debit, increasing what msg.sender owes)
    ///   2. currency.transfer(to, amount)
    ///      (actually transfer the tokens out)
    function take(Currency currency, address to, uint256 amount) external override onlyWhenUnlocked {
        // TODO: Implement
    }

    /// @notice Mints ERC6909 claim tokens instead of taking real tokens
    /// @dev LOGIC:
    ///   1. _accountDelta: credit the value (reduces delta)
    ///      Actually for mint: delta goes negative meaning pool "owes" — but mint satisfies it as a claim
    ///      _accountDelta(CurrencyLibrary.fromId(id), -(amount.toInt256()), msg.sender)
    ///   2. _mint(to, id, amount)  — ERC6909 mint
    function mint(address to, uint256 id, uint256 amount) external override onlyWhenUnlocked {
        // TODO: Implement
    }

    /// @notice Burns ERC6909 claim tokens (pays a debt using claims)
    /// @dev LOGIC:
    ///   1. _accountDelta(CurrencyLibrary.fromId(id), amount.toInt256(), msg.sender)
    ///      (positive = credit, reducing debt)
    ///   2. _burn(from, id, amount)  — ERC6909 burn
    ///   CHECK: msg.sender has allowance/operator permission on 'from'
    function burn(address from, uint256 id, uint256 amount) external override onlyWhenUnlocked {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                    DYNAMIC LP FEE
    // ═══════════════════════════════════════════════════════════

    /// @notice Updates the dynamic LP fee for a pool
    /// @dev CHECKS:
    ///   1. msg.sender == address(key.hooks) → revert UnauthorizedDynamicLPFeeUpdate
    ///   2. key.fee.isDynamicFee() → must be a dynamic fee pool
    ///   3. newDynamicLPFee <= MAX_LP_FEE → revert LPFeeTooLarge
    ///
    /// LOGIC:
    ///   1. Load pool's slot0
    ///   2. Update lpFee field in slot0
    ///   3. Store back
    function updateDynamicLPFee(PoolKey calldata key, uint24 newDynamicLPFee) external override {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                  PROTOCOL FEE OVERRIDES
    // ═══════════════════════════════════════════════════════════

    /// @notice Override from ProtocolFees — sets protocol fee for a pool
    function setProtocolFee(PoolKey calldata key, uint24 newProtocolFee) external override(IPoolManager, ProtocolFees) {
        // TODO: Implement
        // 1. CHECK: msg.sender == address(protocolFeeController)
        // 2. CHECK: newProtocolFee.isValidProtocolFee()
        // 3. Update pool's slot0 protocolFee field
    }

    /// @notice Override from ProtocolFees — collects accrued protocol fees
    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        override(IPoolManager, ProtocolFees)
        returns (uint256 amountCollected)
    {
        // TODO: Implement
        // 1. CHECK: msg.sender == address(protocolFeeController)
        // 2. amount = amount == 0 ? protocolFeesAccrued[currency] : amount
        // 3. CHECK: amount <= protocolFeesAccrued[currency]
        // 4. protocolFeesAccrued[currency] -= amount
        // 5. currency.transfer(recipient, amount)
    }

    // ═══════════════════════════════════════════════════════════
    //                         VIEWS
    // ═══════════════════════════════════════════════════════════

    /// @notice Whether the PoolManager is currently in an unlocked state
    function isUnlocked() external view override returns (bool unlocked) {
        // TODO: tload(IS_UNLOCKED_SLOT) != 0
    }

    /// @notice Returns the synced reserves for a currency
    function reservesOf(Currency currency) external view override returns (uint256) {
        // TODO: Read from transient reserves slot
    }

    // ═══════════════════════════════════════════════════════════
    //                 INTERNAL: DELTA ACCOUNTING
    // ═══════════════════════════════════════════════════════════

    /// @notice Updates the currency delta for a given caller in transient storage
    /// @dev THIS IS THE CORE OF FLASH ACCOUNTING.
    ///
    /// LOGIC:
    ///   1. Compute the transient storage slot:
    ///      slot = keccak256(abi.encodePacked(caller, uint256(currency.toId())))
    ///   2. Read current delta from tload(slot)
    ///   3. new delta = current + deltaAmount
    ///   4. tstore(slot, new delta)
    ///   5. Update nonzero delta count:
    ///      - If current != 0 AND new == 0: decrement nonzeroDeltaCount
    ///      - If current == 0 AND new != 0: increment nonzeroDeltaCount
    ///      (Track how many caller+currency pairs have outstanding deltas)
    ///
    /// @param currency The currency being accounted
    /// @param delta The signed delta (positive = credit/pool receives, negative = debit/pool pays)
    /// @param caller The address whose delta is being updated
    function _accountDelta(Currency currency, int256 delta, address caller) internal {
        // TODO: Implement using transient storage (tload/tstore)
    }

    /// @notice Computes the transient storage slot for a caller's currency delta
    /// @dev slot = keccak256(abi.encodePacked(caller, currency.toId()))
    function _computeDeltaSlot(address caller, Currency currency) internal pure returns (bytes32 slot) {
        // TODO: Implement
        // assembly { ... keccak256 ... }
    }

    /// @notice Computes the transient storage slot for currency reserves
    /// @dev slot = keccak256(abi.encode(currency, RESERVES_OF_SLOT))
    function _computeReservesSlot(Currency currency) internal pure returns (bytes32 slot) {
        // TODO: Implement
    }

    // ═══════════════════════════════════════════════════════════
    //                 INTERNAL: POOL ACCESS
    // ═══════════════════════════════════════════════════════════

    /// @notice Gets a pool state, reverting if not initialized
    /// @dev LOGIC:
    ///   1. poolId = key.toId()
    ///   2. pool = _pools[poolId]
    ///   3. CHECK: pool.slot0.sqrtPriceX96() != 0 → revert PoolNotInitialized
    function _getPool(PoolKey calldata key) internal view returns (Pool.State storage pool) {
        // TODO: Implement — add pool-not-initialized check
        bytes32 id = key.toId();
        pool = _pools[id];
    }

    // ═══════════════════════════════════════════════════════════
    //                      RECEIVE ETH
    // ═══════════════════════════════════════════════════════════

    /// @dev Accept native ETH for settlements
    receive() external payable {}
}
