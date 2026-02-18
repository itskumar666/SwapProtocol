// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title UnsafeMath — gas-optimized math without overflow/underflow checks
library UnsafeMath {
    /// @notice Division without zero-check
    function divRoundingUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := add(div(x, d), gt(mod(x, d), 0))
        }
    }
}
