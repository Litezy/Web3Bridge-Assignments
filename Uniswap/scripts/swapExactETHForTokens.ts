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

  const ethValue = ethers.parseUnits("0.05", 18); // sending 0.05 ETH
  const amountOutMin = ethers.parseUnits("98", 6); // minimum USDC expected
  const path = ["0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", USDCAddress]; // WETH → USDC
  const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

  const usdcBefore = await USDC.balanceOf(signer.address);
  const ethBefore = await ethers.provider.getBalance(signer);

  console.log("=================Before========================================");
  console.log("USDC Balance before swap:", ethers.formatUnits(usdcBefore, 6));
  console.log("ETH Balance before swap:", ethers.formatUnits(ethBefore, 18));

  const tx = await ROUTER.swapExactETHForTokens(
    amountOutMin,
    path,
    signer.address,
    deadline,
    { value: ethValue }
  );
  await tx.wait();

  const usdcAfter = await USDC.balanceOf(signer.address);
  const ethAfter = await ethers.provider.getBalance(signer);

  console.log("=================After========================================");
  console.log("USDC Balance after swap:", ethers.formatUnits(usdcAfter, 6));
  console.log("ETH Balance after swap:", ethers.formatUnits(ethAfter, 18));
  console.log("Swapped successfully!");
  console.log("=========================================================");
  console.log("ETH spent:", ethers.formatUnits(ethBefore - ethAfter, 18));
  console.log("USDC received:", ethers.formatUnits(usdcAfter - usdcBefore, 6));
};

main().catch(console.error);