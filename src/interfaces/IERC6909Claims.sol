// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC6909Claims — multi-token standard for internal balances (claims)
/// @notice Minimal ERC6909 interface for surplus token accounting in PoolManager
interface IERC6909Claims {
    // ─── Events ────────────────────────────────────────────────
    event Transfer(address caller, address indexed from, address indexed to, uint256 indexed id, uint256 amount);
    event OperatorSet(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    // ─── Views ─────────────────────────────────────────────────

    /// @notice Returns the balance of a token id for an owner
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /// @notice Returns the allowance of a spender for a token id
    function allowance(address owner, address spender, uint256 id) external view returns (uint256);

    /// @notice Returns whether an operator is approved for all tokens of an owner
    function isOperator(address owner, address operator) external view returns (bool);

    // ─── Mutations ─────────────────────────────────────────────

    /// @notice Transfers tokens from caller to a recipient
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);

    /// @notice Transfers tokens from a sender to a recipient (requires allowance)
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);

    /// @notice Approves a spender to transfer a specific amount of a token id
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);

    /// @notice Sets or revokes operator status for all token ids
    function setOperator(address operator, bool approved) external returns (bool);
}
