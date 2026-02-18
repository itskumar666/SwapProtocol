// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "./BitMath.sol";

/// @title TickBitmap — compressed mapping of initialized ticks
/// @notice Stores a packed bitmap indicating which ticks are initialized
/// @dev Each tick's initialized state is stored as a single bit in a mapping(int16 => uint256)
///      where the key is the tick's "word position" (tick / 256) and the bit is (tick % 256)
library TickBitmap {
    /// @notice Computes the word position and bit position for a tick
    /// @dev LOGIC:
    ///   wordPos = int16(tick >> 8)        — which 256-bit word
    ///   bitPos  = uint8(uint24(tick % 256))  — which bit within that word
    ///   Note: for negative ticks, Solidity's >> on int24 gives arithmetic shift
    ///         and % may give negative result, so use uint8(uint24(tick % 256))
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        // TODO: Implement
        // wordPos = int16(tick >> 8)
        // bitPos = uint8(uint24(tick % 256))
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
        return (wordPos, bitPos);
    }

    /// @notice Flips the initialized state of a tick in the bitmap
    /// @dev LOGIC:
    ///   1. (wordPos, bitPos) = position(tick / tickSpacing)
    ///      - We compress by tickSpacing so only aligned ticks are stored
    ///   2. mask = 1 << bitPos
    ///   3. self[wordPos] ^= mask
    ///      - XOR flips the bit: 0→1 (initialize) or 1→0 (uninitialize)
    /// @param self The bitmap mapping
    /// @param tick The tick to flip (must be divisible by tickSpacing)
    /// @param tickSpacing The tick spacing of the pool
    function flipTick(mapping(int16 => uint256) storage self, int24 tick, int24 tickSpacing) internal {
        // TODO: Implement
        // CHECK: tick % tickSpacing == 0 (assert or require)
        if(tick % tickSpacing != 0) {
            revert("Tick not aligned with tick spacing");
        }
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;

    }

    /// @notice Finds the next initialized tick within one word, to the left (less than or equal)
    /// @dev LOGIC:
    ///   This is used during swaps to find the next tick boundary.
    ///
    ///   1. compressed = tick / tickSpacing
    ///      - If tick < 0 AND tick % tickSpacing != 0, subtract 1 (round towards negative infinity)
    ///   2. if lte (searching left or at current):
    ///      a. (wordPos, bitPos) = position(compressed)
    ///      b. mask = (1 << bitPos) - 1 + (1 << bitPos)   — all bits at and below bitPos
    ///      c. masked = self[wordPos] & mask
    ///      d. if masked != 0:
    ///           initialized = true
    ///           next = (compressed - (bitPos - mostSignificantBit(masked))) * tickSpacing
    ///         else:
    ///           initialized = false
    ///           next = (compressed - bitPos) * tickSpacing
    ///
    ///   3. if !lte (searching right/strictly greater):
    ///      a. (wordPos, bitPos) = position(compressed + 1)
    ///      b. mask = ~((1 << bitPos) - 1)   — all bits at and above bitPos
    ///      c. masked = self[wordPos] & mask
    ///      d. if masked != 0:
    ///           initialized = true
    ///           next = (compressed + 1 + (leastSignificantBit(masked) - bitPos)) * tickSpacing
    ///         else:
    ///           initialized = false
    ///           next = (compressed + 1 + (type(uint8).max - bitPos)) * tickSpacing
    ///
    /// @param self The bitmap mapping
    /// @param tick The starting tick
    /// @param tickSpacing The pool's tick spacing
    /// @param lte True = search left (<=), False = search right (>)
    /// @return next The next initialized tick (or the boundary of the word)
    /// @return initialized Whether a tick was found in this word
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        // TODO: Implement using the logic above
        uint24 compressed = uint24(tick / tickSpacing);
        if (tick < 0 && tick % tickSpacing != 0) {
            compressed -= 1;
        }       
        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(int24(compressed));
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;
            if (masked != 0) {
                initialized = true;
                next = int24(compressed - (bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing;
            } else {
                initialized = false;
                next = int24(compressed - bitPos) * tickSpacing;
            }
        } else {
            (int16 wordPos, uint8 bitPos) = position(int24(compressed + 1));
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;
            if (masked != 0) {
                initialized = true;
                next = int24(compressed + 1 + (BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing;
            } else {
                initialized = false;
                next = int24(compressed + 1 + (type(uint8).max - bitPos)) * tickSpacing;
            }
        }
        return (next, initialized);
    }
    
}
