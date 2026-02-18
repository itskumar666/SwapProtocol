// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "./types/Currency.sol";
import {PoolKey} from "./types/PoolKey.sol";
import {PoolId} from "./types/PoolId.sol";
import {Pool} from "./libraries/Pool.sol";
import {IProtocolFeeController} from "./interfaces/IProtocolFeeController.sol";
import {ProtocolFeeLibrary} from "./libraries/ProtocolFeeLibrary.sol";
import {Ownable} from "./Ownable.sol";

/// @title ProtocolFees — manages protocol fee collection and controller
/// @notice Inherited by PoolManager to handle protocol fee logic
/// @dev Protocol fees are collected during swaps and stored per-currency
abstract contract ProtocolFees is Ownable {
    using ProtocolFeeLibrary for uint24;

    // ═══════════════════════════════════════════════════════════
    //                       ERRORS
    // ═══════════════════════════════════════════════════════════

    error ControllerCallFailed();
    error ProtocolFeesExceedBalance(Currency currency);

    // ═══════════════════════════════════════════════════════════
    //                       STORAGE
    // ═══════════════════════════════════════════════════════════

    /// @notice The protocol fee controller contract
    IProtocolFeeController public protocolFeeController;

    /// @notice Accumulated protocol fees per currency (currency → amount)
    mapping(Currency => uint256) public protocolFeesAccrued;

    // ═══════════════════════════════════════════════════════════
    //                       FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Sets the protocol fee controller (only owner)
    /// @dev CHECKS:
    ///   1. onlyOwner modifier
    /// LOGIC:
    ///   1. protocolFeeController = controller
    ///   2. emit ProtocolFeeControllerUpdated(address(controller))
    function setProtocolFeeController(IProtocolFeeController controller) external onlyOwner {
        // TODO: Implement
    }

    /// @notice Sets the protocol fee for a pool
    /// @dev CHECKS:
    ///   1. msg.sender == address(protocolFeeController) → revert InvalidCaller
    ///   2. newProtocolFee.isValidProtocolFee() → revert ProtocolFeeTooLarge
    /// LOGIC:
    ///   1. Fetch the Pool.State for the given key
    ///   2. Update slot0's protocolFee field
    ///   3. emit ProtocolFeeUpdated(key.toId(), newProtocolFee)
    ///
    /// NOTE: This function needs access to the pools mapping, which is in PoolManager.
    ///       It's implemented as an abstract function here, overridden in PoolManager.
    function setProtocolFee(PoolKey calldata key, uint24 newProtocolFee) external virtual;

    /// @notice Collects accumulated protocol fees
    /// @dev CHECKS:
    ///   1. msg.sender == address(protocolFeeController) → revert InvalidCaller
    ///   2. amount <= protocolFeesAccrued[currency] → revert ProtocolFeesExceedBalance
    /// LOGIC:
    ///   1. If amount == 0: collect ALL accrued fees for this currency
    ///   2. protocolFeesAccrued[currency] -= amount
    ///   3. Transfer the currency to the recipient
    ///   4. Return the actual amount collected
    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        virtual
        returns (uint256 amountCollected);

    /// @notice Internal: fetch the protocol fee from the controller for a pool
    /// @dev LOGIC:
    ///   1. If protocolFeeController == address(0) → return 0
    ///   2. Try calling protocolFeeController.protocolFeeForPool(key)
    ///   3. If call fails or returns invalid fee → return 0 (don't revert)
    ///   4. Validate: both fee components <= MAX_PROTOCOL_FEE
    ///   5. Return the valid fee
    function _fetchProtocolFee(PoolKey memory key) internal view returns (uint24) {
        // TODO: Implement
    }
}
