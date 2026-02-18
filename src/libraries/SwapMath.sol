// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FullMath} from "./FullMath.sol";
import {SqrtPriceMath} from "./SqrtPriceMath.sol";

/// @title SwapMath — computes the result of a swap within a single tick range
library SwapMath {
    uint256 internal constant MAX_FEE_PIPS = 1_000_000;

    /// @notice Computes the result of swapping some amount in/out within a single tick range
    /// @param sqrtPriceCurrentX96 The current sqrt(price) of the pool
    /// @param sqrtPriceTargetX96 The target sqrt(price) — cannot be crossed
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be used
    /// @param feePips The fee taken from the input amount, in hundredths of a bip (1e-6)
    /// @return sqrtPriceNextX96 The price after swapping within this step
    /// @return amountIn The amount consumed as input
    /// @return amountOut The amount output
    /// @return feeAmount The fee generated
    function computeSwapStep(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (uint160 sqrtPriceNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount)
    {
        unchecked {
            bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;
            bool exactIn = amountRemaining >= 0;

            if (exactIn) {
                // Fee is taken from input
                uint256 amountRemainingLessFee =
                    FullMath.mulDiv(uint256(amountRemaining), MAX_FEE_PIPS - feePips, MAX_FEE_PIPS);

                amountIn = zeroForOne
                    ? SqrtPriceMath.getAmount0Delta(sqrtPriceTargetX96, sqrtPriceCurrentX96, liquidity, true)
                    : SqrtPriceMath.getAmount1Delta(sqrtPriceCurrentX96, sqrtPriceTargetX96, liquidity, true);

                if (amountRemainingLessFee >= amountIn) {
                    // Can reach the target price
                    sqrtPriceNextX96 = sqrtPriceTargetX96;
                } else {
                    // Cannot reach target — compute partial price move
                    sqrtPriceNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                        sqrtPriceCurrentX96, liquidity, amountRemainingLessFee, zeroForOne
                    );
                }
            } else {
                amountOut = zeroForOne
                    ? SqrtPriceMath.getAmount1Delta(sqrtPriceTargetX96, sqrtPriceCurrentX96, liquidity, false)
                    : SqrtPriceMath.getAmount0Delta(sqrtPriceCurrentX96, sqrtPriceTargetX96, liquidity, false);

                if (uint256(-amountRemaining) >= amountOut) {
                    sqrtPriceNextX96 = sqrtPriceTargetX96;
                } else {
                    sqrtPriceNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                        sqrtPriceCurrentX96, liquidity, uint256(-amountRemaining), zeroForOne
                    );
                }
            }

            bool max = sqrtPriceTargetX96 == sqrtPriceNextX96;

            // Compute actual amounts based on direction
            if (zeroForOne) {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount0Delta(sqrtPriceNextX96, sqrtPriceCurrentX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount1Delta(sqrtPriceNextX96, sqrtPriceCurrentX96, liquidity, false);
            } else {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount1Delta(sqrtPriceCurrentX96, sqrtPriceNextX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount0Delta(sqrtPriceCurrentX96, sqrtPriceNextX96, liquidity, false);
            }

            // Cap output at remaining for exact output swaps
            if (!exactIn && amountOut > uint256(-amountRemaining)) {
                amountOut = uint256(-amountRemaining);
            }

            if (exactIn && sqrtPriceNextX96 != sqrtPriceTargetX96) {
                // Didn't reach the target — take the rest as fee
                feeAmount = uint256(amountRemaining) - amountIn;
            } else {
                feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, MAX_FEE_PIPS - feePips);
            }
        }
    }
}
