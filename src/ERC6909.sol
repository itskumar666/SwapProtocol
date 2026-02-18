// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC6909Claims} from "./interfaces/IERC6909Claims.sol";

/// @title ERC6909 — multi-token standard implementation
/// @notice Manages claim token balances for the PoolManager
/// @dev Each currency gets a token ID = uint256(uint160(currencyAddress))
abstract contract ERC6909 is IERC6909Claims {
    // ═══════════════════════════════════════════════════════════
    //                       STORAGE
    // ═══════════════════════════════════════════════════════════

    /// @dev owner → token id → balance
    mapping(address => mapping(uint256 => uint256)) public override balanceOf;

    /// @dev owner → spender → token id → allowance
    mapping(address => mapping(address => mapping(uint256 => uint256))) public override allowance;

    /// @dev owner → operator → approved for all
    mapping(address => mapping(address => bool)) public override isOperator;

    // ═══════════════════════════════════════════════════════════
    //                       FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Transfer tokens from msg.sender to receiver
    /// @dev CHECKS:
    ///   1. msg.sender must have sufficient balance
    /// LOGIC:
    ///   1. balanceOf[msg.sender][id] -= amount
    ///   2. balanceOf[receiver][id] += amount
    ///   3. emit Transfer(msg.sender, msg.sender, receiver, id, amount)
    function transfer(address receiver, uint256 id, uint256 amount) external override returns (bool) {
        // TODO: Implement
        require(balanceOf[msg.sender][id] >= amount, "Insufficient balance");
        unchecked {
            balanceOf[msg.sender][id] -= amount;
            balanceOf[receiver][id] += amount;
        }
        emit Transfer(msg.sender, msg.sender, receiver, id, amount);
        return true;
    }

    /// @notice Transfer tokens from sender to receiver (requires allowance or operator)
    /// @dev CHECKS:
    ///   1. If msg.sender != sender:
    ///      a. Check isOperator[sender][msg.sender] → skip allowance check
    ///      b. Else: allowance[sender][msg.sender][id] >= amount
    ///         - If allowance != type(uint256).max: deduct allowance
    ///   2. sender must have sufficient balance
    /// LOGIC:
    ///   1. Handle allowance deduction (if not operator and not infinite)
    ///   2. balanceOf[sender][id] -= amount
    ///   3. balanceOf[receiver][id] += amount
    ///   4. emit Transfer(msg.sender, sender, receiver, id, amount)
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount)
        external
        override
        returns (bool)
    {
        // TODO: Implement
        if (msg.sender != sender) {
            if (!isOperator[sender][msg.sender]) {
                require(allowance[sender][msg.sender][id] >= amount, "Allowance exceeded");
                _decreaseAllowance(sender, msg.sender, id, amount);
            }
        }
        require(balanceOf[sender][id] >= amount, "Insufficient balance");
        unchecked {
            balanceOf[sender][id] -= amount;
            balanceOf[receiver][id] += amount;  
        }
    }

    /// @notice Approve a spender for a specific token id
    /// @dev LOGIC:
    ///   1. allowance[msg.sender][spender][id] = amount
    ///   2. emit Approval(msg.sender, spender, id, amount)
    function approve(address spender, uint256 id, uint256 amount) external override returns (bool) {
        // TODO: Implement
        allowance[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;

    }

    /// @notice Set operator approval for all token ids
    /// @dev LOGIC:
    ///   1. isOperator[msg.sender][operator] = approved
    ///   2. emit OperatorSet(msg.sender, operator, approved)
    function setOperator(address operator, bool approved) external override returns (bool) {
        // TODO: Implement
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        return true;
    }

    // ═══════════════════════════════════════════════════════════
    //                  INTERNAL MINT/BURN
    // ═══════════════════════════════════════════════════════════

    /// @notice Internal: mint claim tokens
    /// @dev LOGIC:
    ///   1. balanceOf[to][id] += amount  (unchecked — trusted caller)
    ///   2. emit Transfer(msg.sender, address(0), to, id, amount)
    function _mint(address to, uint256 id, uint256 amount) internal {
        // TODO: Implement
        unchecked {
            balanceOf[to][id] += amount;
        }
        emit Transfer(msg.sender, address(0), to, id, amount);
    }

    /// @notice Internal: burn claim tokens
    /// @dev CHECKS:
    ///   1. balanceOf[from][id] >= amount
    /// LOGIC:
    ///   1. balanceOf[from][id] -= amount
    ///   2. emit Transfer(msg.sender, from, address(0), id, amount)
    function _burn(address from, uint256 id, uint256 amount) internal {
            unchecked{
            require(balanceOf[from][id] >= amount, "Insufficient balance to burn");
            balanceOf[from][id] -= amount;
            }
            emit Transfer(msg.sender, from, address(0), id, amount);
        // TODO: Implement
    }

    /// @notice Internal: decrease allowance after transferFrom (helper)
    function _decreaseAllowance(address owner, address spender, uint256 id, uint256 amount) internal {
        // TODO: Implement
        uint256 currentAllowance = allowance[owner][spender][id];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Allowance exceeded");
            unchecked {
                allowance[owner][spender][id] = currentAllowance - amount;
            }
        }   
        // Only decrease if allowance is not type(uint256).max (infinite approval)
    }
}
