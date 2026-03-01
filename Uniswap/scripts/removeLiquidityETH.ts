import { ethers } from "hardhat";
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const main = async () => {
  const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const TokenHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

  await helpers.impersonateAccount(TokenHolder);
  const signer = await ethers.getSigner(TokenHolder);

  const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, signer);
  const USDC = await ethers.getContractAt("IERC20", USDCAddress, signer);

  const lpAmount = ethers.parseUnits("0.01", 18); // example LP tokens
  const amountTokenMin = ethers.parseUnits("990", 6);
  const amountETHMin = ethers.parseUnits("0.5", 18);
  const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

  const usdcBefore = await USDC.balanceOf(signer.address);
  const ethBefore = await ethers.provider.getBalance(signer);

  console.log("=================Before========================================");
  console.log("USDC Balance before removing liquidity:", ethers.formatUnits(usdcBefore, 6));
  console.log("ETH Balance before removing liquidity:", ethers.formatUnits(ethBefore, 18));

  const tx = await ROUTER.removeLiquidityETH(
    USDCAddress,
    lpAmount,
    amountTokenMin,
    amountETHMin,
    signer.address,
    deadline
  );
  await tx.wait();

  const usdcAfter = await USDC.balanceOf(signer.address);
  const ethAfter = await ethers.provider.getBalance(signer);;

  console.log("=================After========================================");
  console.log("USDC Balance after removing liquidity:", ethers.formatUnits(usdcAfter, 6));
  console.log("ETH Balance after removing liquidity:", ethers.formatUnits(ethAfter, 18));
  console.log("Liquidity removed successfully!");
  console.log("=========================================================");
};

main().catch(console.error);