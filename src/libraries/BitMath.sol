// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title BitMath — find MSB and LSB in a uint256
/// @notice Used by TickBitmap for finding next initialized ticks
library BitMath {
    error BitMathZero();

    /// @notice Returns the index of the most significant bit of x
    /// @dev LOGIC — binary search approach:
    ///   If x >= 2^128: msb += 128, x >>= 128
    ///   If x >= 2^64:  msb += 64,  x >>= 64
    ///   If x >= 2^32:  msb += 32,  x >>= 32
    ///   If x >= 2^16:  msb += 16,  x >>= 16
    ///   If x >= 2^8:   msb += 8,   x >>= 8
    ///   If x >= 2^4:   msb += 4,   x >>= 4
    ///   If x >= 2^2:   msb += 2,   x >>= 2
    ///   If x >= 2^1:   msb += 1
    ///
    /// CHECK: x must be > 0 → revert BitMathZero
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        if (x == 0) revert BitMathZero();
        if (x >= 2**128) { x >>= 128; msb += 128; } 

        if (x >= 2**64)  { x >>= 64;  msb += 64; } 
        if (x >= 2**32)  { x >>= 32;  msb += 32; }
        if (x >= 2**16)  { x >>= 16;  msb += 16; }
        if (x >= 2**8)   { x >>= 8;   msb += 8; }
        if (x >= 2**4)   { x >>= 4;   msb += 4; }
        if (x >= 2**2)   { x >>= 2;   msb += 2; }
        if (x >= 2**1)   {             msb += 1; }


    }

    /// @notice Returns the index of the least significant bit of x
    /// @dev LOGIC — similar binary search, but working from the bottom:
    ///   If x & (2^128 - 1) == 0: lsb += 128, x >>= 128
    ///   If x & (2^64 - 1) == 0:  lsb += 64,  x >>= 64
    ///   ... and so on down to 1
    ///
    /// CHECK: x must be > 0 → revert BitMathZero
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        // TODO: Implement binary search for LSB
        if (x == 0) revert BitMathZero();
        if (x & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) { x >>= 128; lsb += 128; } //explain: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF is 2^128 - 1, so this checks if the lower 128 bits are all zero   // explain lower bits:
        if (x & 0xFFFFFFFFFFFFFFFF == 0) { x >>= 64; lsb += 64; } //explain: 0xFFFFFFFFFFFFFFFF is 2^64 - 1, so this checks if the lower 64 bits are all zero
        if (x & 0xFFFFFFFF == 0) { x >>= 32; lsb += 32; }
        if (x & 0xFFFF == 0) { x >>=        16; lsb += 16; }
        if (x & 0xFF == 0) { x >>=          8; lsb += 8; }
        if (x & 0xF == 0            ) { x >>=          4; lsb += 4; }
        if (x & 0x3 == 0            ) { x >>=          2; lsb += 2; }
        if (x & 0x1 == 0            ) {             lsb += 1; }     
    }
}
