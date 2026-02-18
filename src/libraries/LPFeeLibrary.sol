// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title LPFeeLibrary — LP fee constants and helpers
/// @notice Handles static and dynamic LP fees
library LPFeeLibrary {
    /// @notice Maximum LP fee is 100% (1_000_000 pips)
    uint24 public constant MAX_LP_FEE = 1_000_000;

    /// @notice Flag indicating the pool uses dynamic fees (bit 23)
    /// @dev When set in PoolKey.fee, the fee is queried from the hooks contract
    uint24 public constant DYNAMIC_FEE_FLAG = 0x800000;

    /// @notice Flag indicating the hook overrides the LP fee for a specific swap (bit 22)
    uint24 public constant OVERRIDE_FEE_FLAG = 0x400000;

    error LPFeeTooLarge(uint24 fee);

    /// @notice Returns true if the fee has the DYNAMIC_FEE_FLAG set
    /// @dev LOGIC: return fee & DYNAMIC_FEE_FLAG != 0
    function isDynamicFee(uint24 fee) internal pure returns (bool) {
        if ((fee & DYNAMIC_FEE_FLAG) != 0) { //
            return true;
        }
        return false;
        // TODO: Implement
    }

    /// @notice Validates that the fee is within bounds
    /// @dev CHECKS:
    ///   1. If fee has DYNAMIC_FEE_FLAG set → valid (actual fee comes from hooks)
    ///   2. Else fee must be <= MAX_LP_FEE → revert LPFeeTooLarge
    function isValid(uint24 fee) internal pure returns (bool) {
            if ((fee & DYNAMIC_FEE_FLAG) != 0) {
                return true; // Dynamic fee is valid regardless of value
            } else if ((fee & ~DYNAMIC_FEE_FLAG) <= MAX_LP_FEE) { // Mask off dynamic flag to get actual fee
                return true; // Static fee is valid if <= MAX_LP_FEE
            } else {
                revert LPFeeTooLarge(fee & ~DYNAMIC_FEE_FLAG); // Fee is too large, mask off flag for error message
            }
        // TODO: Implement
    }

    /// @notice Removes override flags to get the base fee
    /// @dev LOGIC: return fee & 0x3FFFFF (mask off top 2 bits)
    function getInitialLPFee(uint24 fee) internal pure returns (uint24) {
        // TODO: Implement
            return fee & 0x3FFFFF; // Mask off top 2 bits to get base fee
        // If isDynamicFee → return 0 (will be set via hook)
        // Else → validate and return fee
    }

    /// @notice Returns the effective fee, considering override
    /// @dev If OVERRIDE_FEE_FLAG is set in hookFee, use hookFee (masked)
    ///      Else use the pool's stored LP fee
    function getEffectiveLPFee(uint24 hookReturnedFee, uint24 poolLPFee) internal pure returns (uint24) {
        if ((hookReturnedFee & OVERRIDE_FEE_FLAG) != 0) {
            return hookReturnedFee & 0x3FFFFF; // Mask off flags to get overridden fee
        } else {
            return poolLPFee & 0x3FFFFF; // Mask off flags to get base fee
        }
        // TODO: Implement
    }
}
