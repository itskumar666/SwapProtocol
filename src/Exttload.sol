// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Exttload — external transient storage read access (EIP-1153)
/// @notice Allows reading transient storage slots (used for flash accounting deltas)
/// @dev Requires Cancun EVM (TLOAD opcode)
abstract contract Exttload {
    /// @notice Reads a single transient storage slot
    /// @dev LOGIC: Use assembly tload(slot)
    function exttload(bytes32 slot) external view returns (bytes32 value) {
        // TODO: Implement with assembly
        // assembly { value := tload(slot) }
    }

    /// @notice Reads multiple transient storage slots
    /// @dev LOGIC: For each slot, tload and return
    function exttload(bytes32[] calldata slots) external view returns (bytes32[] memory) {
        // TODO: Implement with assembly loop
    }
}
