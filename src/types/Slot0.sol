// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Slot0 — packed pool state in a single storage slot
/// @notice Contains sqrtPriceX96, tick, protocolFee, and lpFee
/// @dev Layout: [sqrtPriceX96 (160)][tick (24)][protocolFee (24)][lpFee (24)][unused (24)]
type Slot0 is bytes32;

using Slot0Library for Slot0 global;

library Slot0Library {
    uint8 internal constant TICK_OFFSET = 96;
    uint8 internal constant PROTOCOL_FEE_OFFSET = 72;
    uint8 internal constant LP_FEE_OFFSET = 48;

    // Masks
    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 internal constant MASK_24 = (1 << 24) - 1;

    // ──────────────────────────────────────────────────────
    // Bit layout (256 bits total, big-endian):
    //   [255..96]  sqrtPriceX96   (160 bits)
    //   [95..72]   tick           (24 bits, signed)
    //   [71..48]   protocolFee    (24 bits)
    //   [47..24]   lpFee          (24 bits)
    //   [23..0]    unused         (24 bits)
    // ──────────────────────────────────────────────────────

    function sqrtPriceX96(Slot0 _packed) internal pure returns (uint160 _sqrtPriceX96) {
        assembly ("memory-safe") {
            _sqrtPriceX96 := shr(96, _packed)
        }
    }

    function tick(Slot0 _packed) internal pure returns (int24 _tick) {
        assembly ("memory-safe") {
            _tick := signextend(2, shr(72, _packed))
        }
    }

    function protocolFee(Slot0 _packed) internal pure returns (uint24 _protocolFee) {
        assembly ("memory-safe") {
            _protocolFee := and(shr(48, _packed), MASK_24)
        }
    }

    function lpFee(Slot0 _packed) internal pure returns (uint24 _lpFee) {
        assembly ("memory-safe") {
            _lpFee := and(shr(24, _packed), MASK_24)
        }
    }

    function setSqrtPriceX96(Slot0 _packed, uint160 _sqrtPriceX96) internal pure returns (Slot0) {
        assembly ("memory-safe") {
            _packed := or(and(_packed, not(shl(96, MASK_160))), shl(96, and(_sqrtPriceX96, MASK_160)))
        }
        return _packed;
    }

    function setTick(Slot0 _packed, int24 _tick) internal pure returns (Slot0) {
        assembly ("memory-safe") {
            _packed := or(and(_packed, not(shl(72, MASK_24))), shl(72, and(_tick, MASK_24)))
        }
        return _packed;
    }

    function setProtocolFee(Slot0 _packed, uint24 _protocolFee) internal pure returns (Slot0) {
        assembly ("memory-safe") {
            _packed := or(and(_packed, not(shl(48, MASK_24))), shl(48, and(_protocolFee, MASK_24)))
        }
        return _packed;
    }

    function setLpFee(Slot0 _packed, uint24 _lpFee) internal pure returns (Slot0) {
        assembly ("memory-safe") {
            _packed := or(and(_packed, not(shl(24, MASK_24))), shl(24, and(_lpFee, MASK_24)))
        }
        return _packed;
    }
}
