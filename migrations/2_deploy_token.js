const HBCT = artifacts.require("HBCT");

module.exports = function (deployer) {
    const tName = "HeartBit Coin";
    const tSymbol = "HBCT1";
    //const totalAmount = "1000000000000000000000000000000000"; // Test Network
    const totalAmount = "1000000000000000000000000"; // Main Network
    const tTaxFee = 5;
    const tLiquidityFee = 0;

    // --- Main Net ---
    const tDecimals = 9;
    //const tUniswapV2Router = "0x05ff2b0db69458a0750badebc4f9e13add608c7f"; // PancakeSwap v1 Router
    const tUniswapV2Router = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // PancakeSwap v2 Router

    // --- Test Net ---
    //const tDecimals = 18;
    //const tUniswapV2Router = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"; // PancakeSwap Router
    //const tUniswapV2Router = "0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F"; // BakerySwap Router

    deployer.deploy(HBCT, 
        tName,
        tSymbol,
        totalAmount,
        tDecimals,
        tTaxFee,
        tLiquidityFee,
        tUniswapV2Router);
};