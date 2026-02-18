// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FullMath} from "./FullMath.sol";
import {FixedPoint128} from "./FixedPoint128.sol";
import {LiquidityMath} from "./LiquidityMath.sol";

/// @title Position — manages per-position state for concentrated liquidity
/// @notice Each position is keyed by (owner, tickLower, tickUpper, salt)
library Position {
    error CannotUpdateEmptyPosition();

    // ═══════════════════════════════════════════════════════════
    //                       DATA STRUCTURES
    // ═══════════════════════════════════════════════════════════

    struct State {
        /// @notice The amount of liquidity owned by this position
        uint128 liquidity;
        /// @notice Fee growth per unit of liquidity as of the last update (token0)
        /// @dev Stored so we can compute: feesOwed = (feeGrowthInside - feeGrowthInsideLast) * liquidity
        uint256 feeGrowthInside0LastX128;
        /// @notice Fee growth per unit of liquidity as of the last update (token1)
        uint256 feeGrowthInside1LastX128;
    }

    // ═══════════════════════════════════════════════════════════
    //                       FUNCTIONS
    // ═══════════════════════════════════════════════════════════

    /// @notice Calculates the position key from its components
    /// @dev The position key is: keccak256(abi.encodePacked(owner, tickLower, tickUpper, salt))
    /// @param owner The position owner
    /// @param tickLower The lower tick boundary
    /// @param tickUpper The upper tick boundary
    /// @param salt A unique salt to allow multiple positions per range
    /// @return key The position's storage key (bytes32)
    function calculatePositionKey(address owner, int24 tickLower, int24 tickUpper, bytes32 salt)
        internal
        pure
        returns (bytes32)
    {
        // TODO: Implement
        bytes32 Key = keccak256(abi.encodePacked(owner, tickLower, tickUpper, salt));
        return Key;
        // LOGIC: key = keccak256(abi.encodePacked(owner, tickLower, tickUpper, salt))
        // Use assembly for gas efficiency if desired
    }

    /// @notice Updates a position's liquidity and computes fees owed
    /// @dev LOGIC:
    ///   1. Load the current position state from self[positionKey]
    ///   2. CHECK: if liquidityDelta == 0 AND position.liquidity == 0 → revert CannotUpdateEmptyPosition
    ///      (can't poke a position that doesn't exist)
    ///
    ///   3. Calculate fees owed since last update:
    ///      feesOwed0 = FullMath.mulDiv(
    ///          feeGrowthInside0X128 - position.feeGrowthInside0LastX128,
    ///          position.liquidity,
    ///          FixedPoint128.Q128
    ///      )
    ///      feesOwed1 = FullMath.mulDiv(
    ///          feeGrowthInside1X128 - position.feeGrowthInside1LastX128,
    ///          position.liquidity,
    ///          FixedPoint128.Q128
    ///      )
    ///      NOTE: subtraction must be unchecked (fee growth intentionally overflows)
    ///
    ///   4. Update the position:
    ///      - position.liquidity += liquidityDelta (use LiquidityMath.addDelta if signed, or cast)
    ///      - position.feeGrowthInside0LastX128 = feeGrowthInside0X128
    ///      - position.feeGrowthInside1LastX128 = feeGrowthInside1X128
    ///
    ///   5. Store back to self[positionKey]
    ///
    /// @param self The mapping of position key → State
    /// @param positionKey The position's key (from calculatePositionKey)
    /// @param liquidityDelta Signed change in liquidity
    /// @param feeGrowthInside0X128 Current fee growth inside the tick range for token0
    /// @param feeGrowthInside1X128 Current fee growth inside the tick range for token1
    /// @return feesOwed0 Fees owed in token0
    /// @return feesOwed1 Fees owed in token1
    function update(
        mapping(bytes32 => Position.State) storage self,
        bytes32 positionKey,
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal returns (uint256 feesOwed0, uint256 feesOwed1) {
     Position.State storage position = self[positionKey]; 
     require(position.liquidity==0 || liquidityDelta==0,"Insufficient liquidity");
    uint256 feesOwed0 =FullMath.mulDiv(feeGrowthInside0X128-position.feeGrowthInside0LastX128, position.liquidity, FixedPoint128.Q128);
      feesOwed1 = FullMath.mulDiv(
         feeGrowthInside1X128 - position.feeGrowthInside1LastX128,
             position.liquidity,
              FixedPoint128.Q128);
    position.liquidity = LiquidityMath.addDelta(position.liquidity,liquidityDelta);
    uint256 feesOwed1 = FullMath.mulDiv(
         feeGrowthInside1X128 - position.feeGrowthInside1LastX128,  
             position.liquidity,
              FixedPoint128.Q128);  

     position.feeGrowthInside0LastX128 = feeGrowthInside0X128;
     position.feeGrowthInside1LastX128 = feeGrowthInside1X128;
        self[positionKey] = position;
        return (feesOwed0, feesOwed1);



    }
}
