const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
  const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const WETHHolder = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";
  const USDCRECEIVER = "0x6E4E768267B0E1e033B085aB6be4775Dd42B4b1E";

  await helpers.impersonateAccount(WETHHolder);
  const impersonatedSigner = await ethers.getSigner(WETHHolder);


  const amountOut = ethers.parseUnits("1000", 6);
  const addresses = [WETHAddress, USDCAddress];
  const deadline = Math.floor(Date.now() / 1000) + 60 * 10;


  const USDC = await ethers.getContractAt(
    "IERC20",
    USDCAddress,
    impersonatedSigner,
  );
 
  const ROUTER = await ethers.getContractAt(
    "IUniswapV2Router",
    UNIRouter,
    impersonatedSigner,
  );

  // await WETH.approve(UNIRouter, amountOut);

  const usdcBalBefore = await USDC.balanceOf(USDCRECEIVER);
  const ethBalBefore = await ethers.provider.getBalance(impersonatedSigner);
  console.log(
    "=================Before========================================",
  );

  console.log("USDC Balance before swap:", Number(usdcBalBefore));
  console.log("ETH Balance before swap:", ethers.formatEther(ethBalBefore));

  const tx = await ROUTER.swapETHForExactTokens(
    amountOut,
    addresses,
    USDCRECEIVER,
    deadline,
    { value: ethers.parseEther("1") }
  )

  await tx.wait();

  const usdcBalAfter = await USDC.balanceOf(USDCRECEIVER);
  const ethBalAfter = await ethers.provider.getBalance(impersonatedSigner);
  // const wethBalAfter = await WETH.balanceOf(impersonatedSigner.address);
  console.log("=================After========================================");
  console.log("USDC Balance after swap:", ethers.formatUnits(usdcBalAfter, 6));
  console.log("ETH Balance after swap:", ethers.formatEther(ethBalAfter));


  console.log("Swapped successfully!");
  console.log("=========================================================");
  const usdcUsed = usdcBalAfter - usdcBalBefore;
  const ethSent = ethBalBefore - ethBalAfter ;

  console.log("USDC RECEIVED:", ethers.formatUnits(usdcUsed, 6));
  console.log("ETH SENT:", ethers.formatEther(ethSent));
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
