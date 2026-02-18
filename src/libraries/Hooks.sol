// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks, ModifyLiquidityParams, SwapParams} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {BeforeSwapDelta} from "../types/BeforeSwapDelta.sol";

/// @title Hooks — validates hook permissions and calls them safely
/// @notice Hook permissions are encoded in the hook contract's ADDRESS
/// @dev The leading bits of the address indicate which hooks are active:
///
///   bit 159 (0x8000...0000) = BEFORE_INITIALIZE
///   bit 158 (0x4000...0000) = AFTER_INITIALIZE
///   bit 157 (0x2000...0000) = BEFORE_ADD_LIQUIDITY
///   bit 156 (0x1000...0000) = AFTER_ADD_LIQUIDITY
///   bit 155 (0x0800...0000) = BEFORE_REMOVE_LIQUIDITY
///   bit 154 (0x0400...0000) = AFTER_REMOVE_LIQUIDITY
///   bit 153 (0x0200...0000) = BEFORE_SWAP
///   bit 152 (0x0100...0000) = AFTER_SWAP
///   bit 151 (0x0080...0000) = BEFORE_DONATE
///   bit 150 (0x0040...0000) = AFTER_DONATE
///   bit 149 (0x0020...0000) = BEFORE_SWAP_RETURNS_DELTA
///   bit 148 (0x0010...0000) = AFTER_SWAP_RETURNS_DELTA
///   bit 147 (0x0008...0000) = AFTER_ADD_LIQUIDITY_RETURNS_DELTA
///   bit 146 (0x0004...0000) = AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA
///
library Hooks {
    // ═══════════════════════════════════════════════════════════
    //                         ERRORS
    // ═══════════════════════════════════════════════════════════

    error HookAddressNotValid(address hooks);
    error InvalidHookResponse();
    error FailedHookCall(address hooks, bytes revertData);
    error HookDeltaExceedsSwapAmount();

    // ═══════════════════════════════════════════════════════════
    //                    PERMISSION FLAGS
    // ═══════════════════════════════════════════════════════════

    uint160 internal constant BEFORE_INITIALIZE_FLAG = 1 << 159;
    uint160 internal constant AFTER_INITIALIZE_FLAG = 1 << 158;
    uint160 internal constant BEFORE_ADD_LIQUIDITY_FLAG = 1 << 157;
    uint160 internal constant AFTER_ADD_LIQUIDITY_FLAG = 1 << 156;
    uint160 internal constant BEFORE_REMOVE_LIQUIDITY_FLAG = 1 << 155;
    uint160 internal constant AFTER_REMOVE_LIQUIDITY_FLAG = 1 << 154;
    uint160 internal constant BEFORE_SWAP_FLAG = 1 << 153;
    uint160 internal constant AFTER_SWAP_FLAG = 1 << 152;
    uint160 internal constant BEFORE_DONATE_FLAG = 1 << 151;
    uint160 internal constant AFTER_DONATE_FLAG = 1 << 150;
    uint160 internal constant BEFORE_SWAP_RETURNS_DELTA_FLAG = 1 << 149;
    uint160 internal constant AFTER_SWAP_RETURNS_DELTA_FLAG = 1 << 148;
    uint160 internal constant AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 147;
    uint160 internal constant AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 146;

    /// @notice Struct to represent all hook permissions (decoded from address)
    struct Permissions {
        bool beforeInitialize;
        bool afterInitialize;
        bool beforeAddLiquidity;
        bool afterAddLiquidity;
        bool beforeRemoveLiquidity;
        bool afterRemoveLiquidity;
        bool beforeSwap;
        bool afterSwap;
        bool beforeDonate;
        bool afterDonate;
        bool beforeSwapReturnsDelta;
        bool afterSwapReturnsDelta;
        bool afterAddLiquidityReturnsDelta;
        bool afterRemoveLiquidityReturnsDelta;
    }

    // ═══════════════════════════════════════════════════════════
    //                  PERMISSION CHECKERS
    // ═══════════════════════════════════════════════════════════
    //
    // Each function checks a single bit in the hooks address.
    // LOGIC for each: return uint160(address(self)) & FLAG != 0
    //

    function hasPermission(IHooks self, uint160 flag) internal pure returns (bool) {
        // TODO: return uint160(address(self)) & flag != 0
    }

    function beforeInitialize(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, BEFORE_INITIALIZE_FLAG)
    }

    function afterInitialize(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_INITIALIZE_FLAG)
    }

    function beforeAddLiquidity(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, BEFORE_ADD_LIQUIDITY_FLAG)
    }

    function afterAddLiquidity(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_ADD_LIQUIDITY_FLAG)
    }

    function beforeRemoveLiquidity(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, BEFORE_REMOVE_LIQUIDITY_FLAG)
    }

    function afterRemoveLiquidity(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_REMOVE_LIQUIDITY_FLAG)
    }

    function beforeSwap(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, BEFORE_SWAP_FLAG)
    }

    function afterSwap(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_SWAP_FLAG)
    }

    function beforeDonate(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, BEFORE_DONATE_FLAG)
    }

    function afterDonate(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_DONATE_FLAG)
    }

    function beforeSwapReturnsDelta(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, BEFORE_SWAP_RETURNS_DELTA_FLAG)
    }

    function afterSwapReturnsDelta(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_SWAP_RETURNS_DELTA_FLAG)
    }

    function afterAddLiquidityReturnsDelta(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG)
    }

    function afterRemoveLiquidityReturnsDelta(IHooks self) internal pure returns (bool) {
        // TODO: return hasPermission(self, AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
    }

    // ═══════════════════════════════════════════════════════════
    //                  ADDRESS VALIDATION
    // ═══════════════════════════════════════════════════════════

    /// @notice Validates that the hooks address correctly encodes its permissions
    /// @dev CHECKS:
    ///   1. If hooks == address(0), all flags must be zero → OK (no hooks)
    ///   2. If hooks != address(0), at least one flag must be set → revert HookAddressNotValid
    ///   3. "Returns delta" flags must not be set unless the corresponding hook flag is set:
    ///      - BEFORE_SWAP_RETURNS_DELTA → requires BEFORE_SWAP
    ///      - AFTER_SWAP_RETURNS_DELTA → requires AFTER_SWAP
    ///      - AFTER_ADD_LIQUIDITY_RETURNS_DELTA → requires AFTER_ADD_LIQUIDITY
    ///      - AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA → requires AFTER_REMOVE_LIQUIDITY
    ///   4. Validate that the hooks contract exists (code size > 0) if any flags are set
    function validateHookPermissions(IHooks self, Permissions memory permissions) internal pure {
        // TODO: Implement validation
    }

    /// @notice Checks if the hooks address has no hooks enabled (address(0) or no bits set)
    /// @dev LOGIC: return address(self) == address(0)
    function isValidHookAddress(IHooks self, uint24 fee) internal pure returns (bool) {
        // TODO: Implement
        // If fee has the DYNAMIC_FEE_FLAG (0x800000), hooks must have BEFORE_SWAP permission
        // If no hooks (address(0)), no flags should be set
    }

    // ═══════════════════════════════════════════════════════════
    //                    HOOK CALL WRAPPERS
    // ═══════════════════════════════════════════════════════════
    //
    // Each wrapper:
    //   1. Checks if the hook has the corresponding permission flag
    //   2. If not enabled, returns early (no-op)
    //   3. If enabled, calls the hook function via IHooks interface
    //   4. Validates the return value matches the expected selector
    //   5. Reverts with FailedHookCall or InvalidHookResponse on failure
    //

    /// @notice Calls beforeInitialize hook if enabled
    /// @dev LOGIC:
    ///   1. if !self.beforeInitialize() → return (no-op)
    ///   2. bytes4 result = self.beforeInitialize(sender, key, sqrtPriceX96, hookData)
    ///   3. CHECK: result == IHooks.beforeInitialize.selector → else revert InvalidHookResponse
    function callBeforeInitialize(
        IHooks self,
        address sender,
        PoolKey memory key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) internal {
        // TODO: Implement
    }

    /// @notice Calls afterInitialize hook if enabled
    /// @dev Same pattern as beforeInitialize but with tick parameter
    function callAfterInitialize(
        IHooks self,
        address sender,
        PoolKey memory key,
        uint160 sqrtPriceX96,
        int24 tick,
        bytes calldata hookData
    ) internal {
        // TODO: Implement
    }

    /// @notice Calls beforeAddLiquidity hook if enabled
    /// @dev LOGIC: Same pattern — check flag, call, validate selector return
    function callBeforeAddLiquidity(
        IHooks self,
        address sender,
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) internal {
        // TODO: Implement
    }

    /// @notice Calls beforeRemoveLiquidity hook if enabled
    function callBeforeRemoveLiquidity(
        IHooks self,
        address sender,
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) internal {
        // TODO: Implement
    }

    /// @notice Calls afterAddLiquidity hook if enabled
    /// @dev EXTRA: If AFTER_ADD_LIQUIDITY_RETURNS_DELTA is set, decode BalanceDelta from return
    ///   1. Check flag
    ///   2. (bytes4 selector, BalanceDelta hookDelta) = self.afterAddLiquidity(...)
    ///   3. Validate selector
    ///   4. If RETURNS_DELTA flag: return hookDelta
    ///   5. Else: return ZERO_DELTA
    function callAfterAddLiquidity(
        IHooks self,
        address sender,
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal returns (BalanceDelta hookDelta) {
        // TODO: Implement
    }

    /// @notice Calls afterRemoveLiquidity hook if enabled
    /// @dev Same pattern as afterAddLiquidity with RETURNS_DELTA support
    function callAfterRemoveLiquidity(
        IHooks self,
        address sender,
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal returns (BalanceDelta hookDelta) {
        // TODO: Implement
    }

    /// @notice Calls beforeSwap hook if enabled
    /// @dev EXTRA RETURNS:
    ///   - BeforeSwapDelta: hook can take/add tokens to the swap
    ///   - uint24 lpFeeOverride: hook can override the LP fee for this swap
    ///
    /// LOGIC:
    ///   1. Check BEFORE_SWAP flag
    ///   2. (bytes4 selector, BeforeSwapDelta beforeSwapDelta, uint24 lpFeeOverride) = self.beforeSwap(...)
    ///   3. Validate selector
    ///   4. If BEFORE_SWAP_RETURNS_DELTA flag:
    ///      - Validate that delta doesn't exceed amountSpecified
    ///      - Return the delta
    ///   5. Return lpFeeOverride (masked to 24 bits) if dynamic fee pool
    function callBeforeSwap(
        IHooks self,
        address sender,
        PoolKey memory key,
        SwapParams memory params,
        bytes calldata hookData
    ) internal returns (BeforeSwapDelta beforeSwapDelta, uint24 lpFeeOverride) {
        // TODO: Implement
    }

    /// @notice Calls afterSwap hook if enabled
    /// @dev EXTRA: If AFTER_SWAP_RETURNS_DELTA is set, decode int128 unspecifiedDelta from return
    function callAfterSwap(
        IHooks self,
        address sender,
        PoolKey memory key,
        SwapParams memory params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal returns (int128 hookDeltaUnspecified) {
        // TODO: Implement
    }

    /// @notice Calls beforeDonate hook if enabled
    function callBeforeDonate(
        IHooks self,
        address sender,
        PoolKey memory key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) internal {
        // TODO: Implement
    }

    /// @notice Calls afterDonate hook if enabled
    function callAfterDonate(
        IHooks self,
        address sender,
        PoolKey memory key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) internal {
        // TODO: Implement
    }
}
