// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ProtocolFeeLibrary — protocol fee packing/unpacking helpers
/// @notice Protocol fees are packed as two 12-bit values in a uint24:
///   - Upper 12 bits: fee0 direction (token0 → token1)
///   - Lower 12 bits: fee1 direction (token1 → token0)
///   Each value is in hundredths of a bip, max 1000 (= 0.1%)
library ProtocolFeeLibrary {
    /// @notice Maximum protocol fee per direction: 0.1% = 1000 (out of 1_000_000)
    uint24 public constant MAX_PROTOCOL_FEE = 1000;

    /// @dev A zero protocol fee
    uint24 internal constant ZERO = 0;

    /// @notice Extracts the fee for the zero-for-one direction (upper 12 bits)
    /// @dev LOGIC: return uint12(fee >> 12)
    function getZeroForOneFee(uint24 fee) internal pure returns (uint24) {
        // TODO: return fee >> 12
    }

    /// @notice Extracts the fee for the one-for-zero direction (lower 12 bits)
    /// @dev LOGIC: return uint12(fee & 0xFFF)
    function getOneForZeroFee(uint24 fee) internal pure returns (uint24) {
        // TODO: return fee & 0xFFF
    }

    /// @notice Validates both fee components are <= MAX_PROTOCOL_FEE
    /// @dev CHECKS:
    ///   1. getZeroForOneFee(fee) <= MAX_PROTOCOL_FEE
    ///   2. getOneForZeroFee(fee) <= MAX_PROTOCOL_FEE
    function isValidProtocolFee(uint24 fee) internal pure returns (bool) {
        // TODO: Implement
    }

    /// @notice Calculates the portion of the swap fee that goes to protocol
    /// @dev LOGIC:
    ///   Given total swapFee and protocolFee (one direction):
    ///   protocolSwapFee = swapFee * protocolFee / 1_000_000
    ///   (But in V4 the protocol fee is applied differently — see Pool.swap)
    function calculateSwapFee(uint24 protocolFee, uint24 lpFee) internal pure returns (uint24) {
        // TODO: Implement
        // Logic: if protocolFee == 0 return lpFee
        // else: return protocolFee + lpFee * (1_000_000 - protocolFee) / 1_000_000
    }
}
