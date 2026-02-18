// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Extsload — external storage read access
/// @notice Allows anyone to read arbitrary storage slots from the contract
/// @dev Used by off-chain integrations and periphery contracts to read pool state
///      without needing dedicated view functions
abstract contract Extsload {
    /// @notice Reads a single storage slot
    /// @dev LOGIC: Use assembly sload(slot) and return the value
    function extsload(bytes32 slot) external view returns (bytes32 value) {
        // TODO: Implement with assembly
        // assembly { value := sload(slot) }
    }

    /// @notice Reads a contiguous range of storage slots
    /// @dev LOGIC:
    ///   1. Allocate bytes32[] of length nSlots
    ///   2. For i in 0..nSlots: result[i] = sload(startSlot + i)
    ///   3. Return result
    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory) {
        // TODO: Implement with assembly loop
    }

    /// @notice Reads an array of arbitrary (non-contiguous) storage slots
    /// @dev LOGIC: For each slot in the input array, sload and return
    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory) {
        // TODO: Implement with assembly loop
    }
}
