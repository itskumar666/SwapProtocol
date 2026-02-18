// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title LiquidityMath — safe liquidity add/subtract
library LiquidityMath {
    error LiquidityUnderflow();

    /// @notice Add a signed liquidity delta to liquidity and revert on over/underflow
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            z = x - uint128(-y);
            if (z >= x) revert LiquidityUnderflow();
        } else {
            z = x + uint128(y);
            if (z < x) revert LiquidityUnderflow();
        }
    }
}
