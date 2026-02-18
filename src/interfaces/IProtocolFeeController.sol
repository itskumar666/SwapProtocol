// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "../types/Currency.sol";

/// @title IProtocolFeeController — governance-set fee controller
/// @notice External contract that PoolManager queries for protocol fee rates
interface IProtocolFeeController {
    /// @notice Returns the protocol fee for a given pool
    /// @param poolKey The pool to query
    /// @return protocolFee Packed protocol fee (upper 12 bits = fee0, lower 12 bits = fee1)
    ///         Each side is denominated in hundredths of a bip, max 1000 (0.1%)
    function protocolFeeForPool(PoolKey memory poolKey) external view returns (uint24 protocolFee);
}

// Minimal import of PoolKey struct for the interface
import {PoolKey} from "../types/PoolKey.sol";
