import { ethers } from "hardhat";
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const TokenHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";
    const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const FACTORYADDRESS = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";

    await helpers.impersonateAccount(TokenHolder);
    const signer = await ethers.getSigner(TokenHolder);

    const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, signer);
    const USDC = await ethers.getContractAt("IERC20", USDCAddress, signer);
    const FACTORY = await ethers.getContractAt("IUniswapV2Factory", FACTORYADDRESS, signer);

    //get the token pair address
    const pairAddress = await FACTORY.getPair(USDCAddress, WETHAddress);
    //get the liquidity at that pairaddress
    const LP = await ethers.getContractAt("IUniswapV2Pair", pairAddress, signer);
    const lpBefore = await LP.balanceOf(signer.address);

    //get the tokens and reserves
    const token0 = await LP.token0();
    const { reserve0, reserve1 } = await LP.getReserves();

    let reserveUSDC, reserveWETH;

    if (token0.toLowerCase() === USDCAddress.toLowerCase()) {
        reserveUSDC = reserve0;
        reserveWETH = reserve1;
    } else {
        reserveUSDC = reserve1;
        reserveWETH = reserve0;
    }


    const amountTokenDesired = ethers.parseUnits("1000", 6); // 100 USDC
    //amount of eth needed for 100usdc
    const amountETHDesired = (amountTokenDesired * reserveWETH) / reserveUSDC;

    // lets use 10% a our slippage, to be calculated in bps (basis points)
    const slippagePercentage = 1000n // for the pair. i:e, we do 10% for usdc and weth
    const slippageAmount = 10000n - slippagePercentage;
    // for usdc or token
    const amountTokenMin = (amountTokenDesired * slippageAmount) / 10000n

    // for eth 
    const amountETHMin = (amountETHDesired * slippageAmount) / 10000n
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    const usdcBefore = await USDC.balanceOf(signer.address);
    const ethBefore = await ethers.provider.getBalance(signer);

    console.log("=================Before========================================");
    console.log("USDC Balance before removing liquidity:", ethers.formatUnits(usdcBefore, 6));
    console.log("ETH Balance before removing liquidity:", ethers.formatUnits(ethBefore, 18));
    console.log("Initial LP balance:", ethers.formatUnits(lpBefore, 18));

    await USDC.approve(UNIRouter, amountTokenDesired)

    //   add liquidity before removing 
    const tx = await ROUTER.addLiquidityETH(
        USDCAddress,
        amountTokenDesired,
        amountTokenMin,
        amountETHMin,
        signer.address,
        deadline,
        { value: amountETHDesired }
    );
    await tx.wait();

    const usdcAfter = await USDC.balanceOf(signer.address);
    const ethAfter = await ethers.provider.getBalance(signer.address);
    const lpAfter = await LP.balanceOf(signer.address);
    const lpReceived = lpAfter - lpBefore;

    console.log("\n=================After========================================");
    console.log("USDC Balance:", ethers.formatUnits(usdcAfter, 6));
    console.log("ETH Balance:", ethers.formatUnits(ethAfter, 18));
    console.log("LP Balance:", ethers.formatUnits(lpAfter, 18));
    console.log("\nLiquidity added successfully!");
    console.log("=========================================================");
    console.log("USDC spent:", ethers.formatUnits(usdcBefore - usdcAfter, 6));
    console.log("ETH spent:", ethers.formatUnits(ethBefore - ethAfter, 18));
    console.log("LP tokens received:", ethers.formatUnits(lpReceived, 18));


    //Removing liquidity
    const liquidity = await LP.balanceOf(signer.address);
    // refetch reserves  to know the amount to remove

    const { reserve0: r0, reserve1: r1 } = await LP.getReserves();
    const totalSupply = await LP.totalSupply();

    let updatedReserveUSDC, updatedReserveWETH;

    if (token0.toLowerCase() === USDCAddress.toLowerCase()) {
        updatedReserveUSDC = r0;
        updatedReserveWETH = r1;
    } else {
        updatedReserveUSDC = r1;
        updatedReserveWETH = r0;
    }


    const expectedUSDC = (liquidity * updatedReserveUSDC) / totalSupply
    const expectedWETH = (liquidity * updatedReserveWETH) / totalSupply

    const removedUsdcMin = ( expectedUSDC * 1000n) / 10000n
    const removedWethMin = ( expectedWETH * 1000n) / 10000n

    await LP.approve(UNIRouter, liquidity);

    const txn = await ROUTER.removeLiquidityETH(
        USDCAddress,
        liquidity,
        removedUsdcMin,
        removedWethMin,
        signer.address,
        deadline
    );
    await txn.wait();

    const usdcAfterLiquidity = await USDC.balanceOf(signer.address);
    const ethAfterLiqudity = await ethers.provider.getBalance(signer);
    const lpAfterRemoval = await LP.balanceOf(signer.address)

    console.log("=================Liquidity burnt/removed========================================");
    console.log("USDC Balance after removing liquidity:", ethers.formatUnits(usdcAfterLiquidity, 6));
    console.log("ETH Balance after removing liquidity:", ethers.formatUnits(ethAfterLiqudity, 18));
    console.log("Lp Balance after removing liquidity:", ethers.formatUnits(lpAfterRemoval, 18));
    console.log("Liquidity removed successfully!");
    console.log("=========================================================");

};


main().catch(console.error);