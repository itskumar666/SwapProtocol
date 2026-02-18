// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title BeforeSwapDelta — packed int128 pair for hook return values
/// @notice Returned from beforeSwap hooks to indicate specified/unspecified deltas
type BeforeSwapDelta is int256;

using BeforeSwapDeltaLibrary for BeforeSwapDelta global;

function toBeforeSwapDelta(int128 deltaSpecified, int128 deltaUnspecified)
    pure
    returns (BeforeSwapDelta beforeSwapDelta)
{
    assembly ("memory-safe") {
        beforeSwapDelta := or(shl(128, deltaSpecified), and(sub(shl(128, 1), 1), deltaUnspecified))
    }
}

library BeforeSwapDeltaLibrary {
    BeforeSwapDelta public constant ZERO_DELTA = BeforeSwapDelta.wrap(0);

    /// @notice Returns the "specified" portion of the delta
    function getSpecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaSpecified) {
        assembly ("memory-safe") {
            deltaSpecified := sar(128, delta)
        }
    }

    /// @notice Returns the "unspecified" portion of the delta
    function getUnspecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaUnspecified) {
        assembly ("memory-safe") {
            deltaUnspecified := signextend(15, delta)
        }
    }
}
