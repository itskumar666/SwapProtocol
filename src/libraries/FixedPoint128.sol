// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title FixedPoint128
/// @notice Q128 fixed-point format used for fee growth accumulators
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000; // 2^128
}
