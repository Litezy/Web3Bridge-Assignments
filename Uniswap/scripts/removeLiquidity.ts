const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { formatUnits } from "ethers";
import { ethers } from "hardhat";

const main = async () => {
  const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const FACTORY_ADDRESS = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
  const USDCHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

  await helpers.impersonateAccount(USDCHolder);
  const impersonatedSigner = await ethers.getSigner(USDCHolder);

  const amountUSDC = ethers.parseUnits("10000", 6);
  const amountDAI = ethers.parseUnits("10000", 18);
  const amountUSDCMin = ethers.parseUnits("9000", 6);
  const amountDAIMin = ethers.parseUnits("9000", 18);
  const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

  const USDC = await ethers.getContractAt(
    "IERC20",
    USDCAddress,
    impersonatedSigner
  );
  const DAI = await ethers.getContractAt(
    "IERC20",
    DAIAddress,
    impersonatedSigner
  );
  const ROUTER = await ethers.getContractAt(
    "IUniswapV2Router",
    UNIRouter,
    impersonatedSigner
  );

  await USDC.approve(UNIRouter, amountUSDC);
  await DAI.approve(UNIRouter, amountDAI);

  const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
  const daiBalBefore = await DAI.balanceOf(impersonatedSigner.address);
  console.log(
    "=================Before========================================"
  );

  console.log("USDC Balance before adding liquidity:", formatUnits(usdcBalBefore,6));
  console.log("DAI Balance before adding liquidity:", formatUnits(daiBalBefore,18));

  const tx = await ROUTER.addLiquidity(
    USDCAddress,
    DAIAddress,
    amountUSDC,
    amountDAI,
    amountUSDCMin,
    amountDAIMin,
    impersonatedSigner.address,
    deadline
  );

  await tx.wait();

  const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
  const daiBalAfter = await DAI.balanceOf(impersonatedSigner.address);
  console.log("=================After========================================");
  console.log("USDC Balance after adding liquidity:", formatUnits(usdcBalAfter,6));
  console.log("DAI Balance after adding liquidity:", formatUnits(daiBalAfter,18));

  console.log("Liquidity added successfully!");
  console.log("=========================================================");
  const usdcUsed = usdcBalBefore - usdcBalAfter;
  const daiUsed = daiBalBefore - daiBalAfter;

  console.log("USDC USED:", ethers.formatUnits(usdcUsed, 6));
  console.log("DAI USED:", ethers.formatUnits(daiUsed, 18));

  

  //Steps in Removing Liquidity
  // Get Factory contract
  const factory = await ethers.getContractAt("IUniswapV2Factory", FACTORY_ADDRESS, impersonatedSigner)

   // Get pair address
  const pairAddress = await factory.getPair(USDC, DAI);
  console.log("Pair address:", pairAddress);

   // Attach LP token (pair is ERC20)
  const pair = await ethers.getContractAt("IERC20", pairAddress, impersonatedSigner);


  //  Get your LP balance
  const liquidity = await pair.balanceOf(impersonatedSigner.address);
  console.log("LP balance:", ethers.formatUnits(liquidity,18));

   if (liquidity === 0n) {
    throw new Error("No liquidity to remove");
  }

  // Approve router to spend LP tokens
  await pair.approve(UNIRouter, liquidity);
  const txn = await ROUTER.removeLiquidity(
    USDCAddress,
    DAIAddress,
    liquidity,
    amountUSDCMin,
    amountDAIMin,
    impersonatedSigner.address,
    deadline
  );

   await txn.wait();
  console.log("Liquidity removed ✅");

};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});