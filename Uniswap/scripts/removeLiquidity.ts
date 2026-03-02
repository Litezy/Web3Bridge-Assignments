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

  const USDC = await ethers.getContractAt("IERC20", USDCAddress, impersonatedSigner);
  const DAI = await ethers.getContractAt("IERC20", DAIAddress, impersonatedSigner);
  const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, impersonatedSigner);
  const factory = await ethers.getContractAt("IUniswapV2Factory", FACTORY_ADDRESS, impersonatedSigner);

  await USDC.approve(UNIRouter, amountUSDC);
  await DAI.approve(UNIRouter, amountDAI);

  const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
  const daiBalBefore = await DAI.balanceOf(impersonatedSigner.address);

  console.log("=================Before========================================");
  console.log("USDC Balance before adding liquidity:", formatUnits(usdcBalBefore, 6));
  console.log("DAI Balance before adding liquidity:", formatUnits(daiBalBefore, 18));

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

  console.log("=================After Adding Liquidity========================================");
  console.log("USDC Balance:", formatUnits(usdcBalAfter, 6));
  console.log("DAI Balance:", formatUnits(daiBalAfter, 18));
  console.log("USDC used:", ethers.formatUnits(usdcBalBefore - usdcBalAfter, 6));
  console.log("DAI used:", ethers.formatUnits(daiBalBefore - daiBalAfter, 18));
  console.log("Liquidity added successfully!");

  // ── Remove Liquidity ──────────────────────────────────────────────

  const pairAddress = await factory.getPair(USDCAddress, DAIAddress);
  console.log("Pair address:", pairAddress);

  // Use IUniswapV2Pair from your contract interfaces
  const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress, impersonatedSigner);

  const liquidity = await pair.balanceOf(impersonatedSigner.address);
  console.log("LP balance:", ethers.formatUnits(liquidity, 18));

  if (liquidity === 0n) {
    throw new Error("No liquidity to remove");
  }

  // Calculate expected token amounts from reserves with 1% slippage
  const totalSupply = await pair.totalSupply();
  const token0 = await pair.token0();
  const { reserve0, reserve1 } = await pair.getReserves();

  const [reserveUSDC, reserveDAI] =
    token0.toLowerCase() === USDCAddress.toLowerCase()
      ? [reserve0, reserve1]
      : [reserve1, reserve0];

  const expectedUSDC = (liquidity * reserveUSDC) / totalSupply;
  const expectedDAI = (liquidity * reserveDAI) / totalSupply;

  const removeUSDCMin = (BigInt(expectedUSDC) * 99n) / 100n;
const removeDAIMin = (BigInt(expectedDAI) * 99n) / 100n;

  console.log("Expected USDC back:", ethers.formatUnits(expectedUSDC, 6));
  console.log("Expected DAI back:", ethers.formatUnits(expectedDAI, 18));

  await pair.approve(UNIRouter, liquidity);

  const usdcBeforeRemove = await USDC.balanceOf(impersonatedSigner.address);
  const daiBeforeRemove = await DAI.balanceOf(impersonatedSigner.address);

  const txn = await ROUTER.removeLiquidity(
    USDCAddress,
    DAIAddress,
    liquidity,
    removeUSDCMin,
    removeDAIMin,
    impersonatedSigner.address,
    deadline
  );
  await txn.wait();

  const usdcAfterRemove = await USDC.balanceOf(impersonatedSigner.address);
  const daiAfterRemove = await DAI.balanceOf(impersonatedSigner.address);

  console.log("=================After Removing Liquidity========================================");
  console.log("USDC Balance:", formatUnits(usdcAfterRemove, 6));
  console.log("DAI Balance:", formatUnits(daiAfterRemove, 18));
  console.log("USDC received back:", ethers.formatUnits(usdcAfterRemove - usdcBeforeRemove, 6));
  console.log("DAI received back:", ethers.formatUnits(daiAfterRemove - daiBeforeRemove, 18));
  console.log("Liquidity removed ✅");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});