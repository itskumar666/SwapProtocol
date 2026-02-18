// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title PoolId — bytes32 hash identifier for a pool
type PoolId is bytes32;

using PoolIdLibrary for PoolId global;

library PoolIdLibrary {
    function toId(PoolId id) internal pure returns (bytes32) {
        return PoolId.unwrap(id);
    }
}
