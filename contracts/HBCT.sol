// SPDX-License-Identifier: MIT

import "./Fees.sol";

pragma solidity ^0.8.4;

contract HBCT is FeeToAddrDeflAutoLPToken, AbstractBurnableDeflToken {
    constructor(
        string memory tName,
        string memory tSymbol,
        uint256 totalAmount,
        uint256 tDecimals,
        uint256 tTaxFee,
        uint256 tLiquidityFee,
        address tUniswapV2Router
    )
        FeeToAddrDeflAutoLPToken(
            tName,
            tSymbol,
            totalAmount,
            tDecimals,
            tTaxFee,
            tLiquidityFee,
            tUniswapV2Router
        )
    {}

    function totalSupply() external view override returns (uint256) {
        return _tTotal - totalBurned;
    }
}
