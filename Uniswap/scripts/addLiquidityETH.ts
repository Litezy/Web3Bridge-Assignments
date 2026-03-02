import { ethers } from "hardhat";
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const main = async () => {
  const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const UNIFactory = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
  const TokenHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

  await helpers.impersonateAccount(TokenHolder);
  const signer = await ethers.getSigner(TokenHolder);

  const USDC = await ethers.getContractAt("IERC20", USDCAddress, signer);
  const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, signer);
  const FACTORY = await ethers.getContractAt("IUniswapV2Factory", UNIFactory, signer);

  // Query current pool reserves to determine correct ETH ratio
  const pairAddress = await FACTORY.getPair(USDCAddress, WETHAddress);
  const LP = await ethers.getContractAt("IUniswapV2Pair", pairAddress, signer);

  const token0 = await LP.token0();
  const { reserve0, reserve1 } = await LP.getReserves();

  const [reserveUSDC, reserveWETH] = token0.toLowerCase() === USDCAddress.toLowerCase()
      ? [reserve0, reserve1]
      : [reserve1, reserve0];

  const amountTokenDesired = ethers.parseUnits("100", 6); // 100 USDC

  // Calculate ETH needed to match current pool ratio
  const amountETHDesired = (amountTokenDesired * reserveWETH) / reserveUSDC;

  console.log("Current pool ratio:");
  console.log("  USDC reserve:", ethers.formatUnits(reserveUSDC, 6));
  console.log("  WETH reserve:", ethers.formatUnits(reserveWETH, 18));
  console.log("  ETH needed for 100 USDC:", ethers.formatUnits(amountETHDesired, 18));

  // 1% slippage tolerance //calculated in bps(basis points)
  const slippageBps = 100n;
  const amountTokenMin = (amountTokenDesired * (10000n - slippageBps)) / 10000n;
  const amountETHMin = (amountETHDesired * (10000n - slippageBps)) / 10000n;

  const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

  await USDC.approve(UNIRouter, amountTokenDesired);

  const usdcBefore = await USDC.balanceOf(signer.address);
  const ethBefore = await ethers.provider.getBalance(signer.address);
  const lpBefore = await LP.balanceOf(signer.address);

  console.log("\n=================Before========================================");
  console.log("USDC Balance:", ethers.formatUnits(usdcBefore, 6));
  console.log("ETH Balance:", ethers.formatUnits(ethBefore, 18));
  console.log("LP Balance:", ethers.formatUnits(lpBefore, 18));

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

  console.log("\n=================After========================================");
  console.log("USDC Balance:", ethers.formatUnits(usdcAfter, 6));
  console.log("ETH Balance:", ethers.formatUnits(ethAfter, 18));
  console.log("LP Balance:", ethers.formatUnits(lpAfter, 18));
  console.log("\nLiquidity added successfully!");
  console.log("=========================================================");
  console.log("USDC spent:", ethers.formatUnits(usdcBefore - usdcAfter, 6));
  console.log("ETH spent:", ethers.formatUnits(ethBefore - ethAfter, 18));
  console.log("LP tokens received:", ethers.formatUnits(lpAfter - lpBefore, 18));
};

main().catch(console.error);