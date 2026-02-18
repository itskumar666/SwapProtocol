// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IUnlockCallback — callback interface for flash accounting
/// @notice Contracts that call PoolManager.unlock() must implement this
interface IUnlockCallback {
    /// @notice Called by PoolManager after the lock is acquired
    /// @param data Arbitrary data passed by the caller to unlock()
    /// @return Any data to be returned to the original caller via unlock()
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}
