// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Ownable — simple single-owner access control
/// @notice Base contract for PoolManager ownership (protocol fee controller management)
abstract contract Ownable {
    // ═══════════════════════════════════════════════════════════
    //                       STORAGE
    // ═══════════════════════════════════════════════════════════

    address private _owner;

    // ═══════════════════════════════════════════════════════════
    //                       EVENTS
    // ═══════════════════════════════════════════════════════════

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ═══════════════════════════════════════════════════════════
    //                       ERRORS
    // ═══════════════════════════════════════════════════════════

    error NotOwner();
    error InvalidOwner();

    // ═══════════════════════════════════════════════════════════
    //                     CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════

    /// @dev Sets the deployer as the initial owner
    /// LOGIC: _owner = initialOwner; emit OwnershipTransferred(address(0), initialOwner)
    constructor(address initialOwner) {
        // TODO: Implement
        if (initialOwner == address(0)) {
            revert InvalidOwner();
        }
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
        // CHECK: initialOwner != address(0) → revert InvalidOwner
    }

    // ═══════════════════════════════════════════════════════════
    //                       MODIFIERS
    // ═══════════════════════════════════════════════════════════

    /// @notice Restricts function to owner only
    /// @dev CHECK: msg.sender == _owner → else revert NotOwner
    modifier onlyOwner() {
        // TODO: Implement
        if(msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    // ═══════════════════════════════════════════════════════════
    //                       FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Returns the current owner
    function owner() public view returns (address) {
        // TODO: return _owner
        return _owner;
    }

    /// @notice Transfers ownership to a new address
    /// @dev CHECKS:
    ///   1. onlyOwner modifier
    ///   2. newOwner != address(0) → revert InvalidOwner
    /// LOGIC:
    ///   1. emit OwnershipTransferred(_owner, newOwner)
    ///   2. _owner = newOwner
    function transferOwnership(address newOwner) external onlyOwner {
        // TODO: Implement
        if (newOwner == address(0)) {
            revert InvalidOwner();
        }
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
