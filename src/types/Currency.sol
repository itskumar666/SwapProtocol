// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Currency — wraps address as a custom type; address(0) = native ETH
type Currency is address;

using CurrencyLibrary for Currency global;
using {equals as ==, notEquals as !=, greaterThan as >, lessThan as <, greaterThanOrEqualTo as >=} for Currency global;

function equals(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function notEquals(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) != Currency.unwrap(other);
}

function greaterThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) > Currency.unwrap(other);
}

function lessThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) < Currency.unwrap(other);
}

function greaterThanOrEqualTo(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) >= Currency.unwrap(other);
}

/// @title CurrencyLibrary
/// @notice Provides helpers for Currency (native ETH or ERC20)
library CurrencyLibrary {
    /// @notice Sentinel value for native ETH
    Currency public constant ADDRESS_ZERO = Currency.wrap(address(0));

    /// @notice Returns true if the currency is native ETH (address(0))
    function isAddressZero(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == address(0);
    }

    /// @notice Returns the balance of this contract for the given currency
    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        if (isAddressZero(currency)) {
            return address(this).balance;
        }
        // ERC20 balanceOf selector: 0x70a08231
        (bool success, bytes memory data) = Currency.unwrap(currency).staticcall(
            abi.encodeWithSelector(0x70a08231, address(this))
        );
        require(success && data.length >= 32, "CurrencyLibrary: balanceOf failed");
        return abi.decode(data, (uint256));
    }

    /// @notice Returns the balance of a target address for the given currency
    function balanceOf(Currency currency, address owner) internal view returns (uint256) {
        if (isAddressZero(currency)) {
            return owner.balance;
        }
        (bool success, bytes memory data) =
            Currency.unwrap(currency).staticcall(abi.encodeWithSelector(0x70a08231, owner));
        require(success && data.length >= 32, "CurrencyLibrary: balanceOf failed");
        return abi.decode(data, (uint256));
    }

    /// @notice Transfers currency from this contract to a target
    function transfer(Currency currency, address to, uint256 amount) internal {
        if (isAddressZero(currency)) {
            (bool success,) = to.call{value: amount}("");
            require(success, "CurrencyLibrary: native transfer failed");
        } else {
            // ERC20 transfer selector: 0xa9059cbb
            (bool success, bytes memory data) =
                Currency.unwrap(currency).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "CurrencyLibrary: ERC20 transfer failed"
            );
        }
    }

    function toId(Currency currency) internal pure returns (uint256) {
        return uint256(uint160(Currency.unwrap(currency)));
    }

    function fromId(uint256 id) internal pure returns (Currency) {
        return Currency.wrap(address(uint160(id)));
    }
}
