// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {SwapParams} from "../../src/interfaces/IHooks.sol";
import {IUnlockCallback} from "../../src/interfaces/IUnlockCallback.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {BalanceDelta} from "../../src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "../../src/types/Currency.sol";

/// @title PoolSwapTest — test router for executing swaps
/// @notice Wraps the unlock → swap → settle flow for testing
/// @dev YOU implement the callback logic. Structure provided.
contract PoolSwapTest is IUnlockCallback {
    using CurrencyLibrary for Currency;

    IPoolManager public immutable manager;

    /// @dev Struct to pass data through the unlock callback
    struct CallbackData {
        address sender;
        PoolKey key;
        SwapParams params;
        bytes hookData;
        bool settleUsingBurn;
        bool takeClaims;
    }

    error NotPoolManager();

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    /// @notice Entry point: initiates a swap via the PoolManager unlock pattern
    /// @dev LOGIC:
    ///   1. Encode CallbackData with all swap params
    ///   2. Call manager.unlock(encodedData)
    ///   3. Decode and return the BalanceDelta
    function swap(
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData,
        bool settleUsingBurn,
        bool takeClaims
    ) external payable returns (BalanceDelta delta) {
        // TODO: Implement
        // delta = abi.decode(manager.unlock(abi.encode(CallbackData(...))), (BalanceDelta))
    }

    /// @notice Called by PoolManager during unlock
    /// @dev LOGIC:
    ///   1. CHECK: msg.sender == address(manager) → revert NotPoolManager
    ///   2. Decode CallbackData from data
    ///   3. Call manager.swap(key, params, hookData) → get delta
    ///   4. Settlement:
    ///      For each currency (0 and 1):
    ///        If delta < 0 (we owe the pool):
    ///          - If settleUsingBurn: manager.burn(sender, currencyId, amount)
    ///          - Else: transfer tokens from sender to manager, then manager.settle()
    ///        If delta > 0 (pool owes us):
    ///          - If takeClaims: manager.mint(sender, currencyId, amount)
    ///          - Else: manager.take(currency, sender, amount)
    ///   5. Return abi.encode(delta)
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        // TODO: Implement
    }
}
