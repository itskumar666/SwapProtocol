// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {ModifyLiquidityParams} from "../../src/interfaces/IHooks.sol";
import {IUnlockCallback} from "../../src/interfaces/IUnlockCallback.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {BalanceDelta} from "../../src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "../../src/types/Currency.sol";

/// @title PoolModifyLiquidityTest — test router for modifying liquidity
/// @notice Wraps the unlock → modifyLiquidity → settle flow for testing
contract PoolModifyLiquidityTest is IUnlockCallback {
    using CurrencyLibrary for Currency;

    IPoolManager public immutable manager;

    struct CallbackData {
        address sender;
        PoolKey key;
        ModifyLiquidityParams params;
        bytes hookData;
        bool settleUsingBurn;
        bool takeClaims;
    }

    error NotPoolManager();

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    /// @notice Entry point: modifies liquidity via the PoolManager unlock pattern
    /// @dev LOGIC:
    ///   1. Encode CallbackData
    ///   2. Call manager.unlock(encodedData)
    ///   3. Return (callerDelta, feesAccrued)
    function modifyLiquidity(
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData,
        bool settleUsingBurn,
        bool takeClaims
    ) external payable returns (BalanceDelta callerDelta, BalanceDelta feesAccrued) {
        // TODO: Implement
    }

    /// @notice Called by PoolManager during unlock
    /// @dev LOGIC:
    ///   1. CHECK: msg.sender == address(manager)
    ///   2. Decode CallbackData
    ///   3. Call manager.modifyLiquidity(key, params, hookData) → (callerDelta, feesAccrued)
    ///   4. Settlement:
    ///      For each currency (0 and 1):
    ///        If delta > 0 (we owe the pool — adding liquidity):
    ///          - Transfer tokens from sender to manager
    ///          - Call manager.settle()
    ///        If delta < 0 (pool owes us — removing liquidity / fees):
    ///          - Call manager.take(currency, sender, abs(delta))
    ///   5. Return abi.encode(callerDelta, feesAccrued)
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        // TODO: Implement
    }
}
