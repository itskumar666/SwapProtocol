// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title SafeCast — safe casting between integer types
library SafeCast {
    error SafeCastOverflow();

    function toUint160(uint256 x) internal pure returns (uint160 y) {
        y = uint160(x);
        if (y != x) revert SafeCastOverflow();
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        y = uint128(x);
        if (y != x) revert SafeCastOverflow();
    }

    function toInt128(int256 x) internal pure returns (int128 y) {
        y = int128(x);
        if (y != x) revert SafeCastOverflow();
    }

    function toInt128(uint256 x) internal pure returns (int128 y) {
        if (x > uint128(type(int128).max)) revert SafeCastOverflow();
        y = int128(int256(x));
    }

    function toInt256(uint256 x) internal pure returns (int256 y) {
        if (x > uint256(type(int256).max)) revert SafeCastOverflow();
        y = int256(x);
    }

    function toUint256(int256 x) internal pure returns (uint256 y) {
        if (x < 0) revert SafeCastOverflow();
        y = uint256(x);
    }
}
