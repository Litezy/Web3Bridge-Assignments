const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const TokenHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

    await helpers.impersonateAccount(TokenHolder);
    const impersonatedSigner = await ethers.getSigner(TokenHolder);

    const amountOut = ethers.parseUnits("0.05", 18);
    const amountInMax = ethers.parseUnits("100", 6);
    const addresses = [ USDCAddress,WETHAddress];
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    const USDC = await ethers.getContractAt(
        "IERC20",
        USDCAddress,
        impersonatedSigner
    );

    const WETH = await ethers.getContractAt(
    "IERC20",
    WETHAddress,
    impersonatedSigner
  );

    const ROUTER = await ethers.getContractAt(
        "IUniswapV2Router",
        UNIRouter,
        impersonatedSigner
    );

    await USDC.approve(UNIRouter,amountOut);
    // check balance
    const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
    const ethBalanceBefore = await ethers.provider.getBalance(impersonatedSigner);
    console.log(
        "=================Before========================================",
    );
    console.log("USDC Balance before swap:", ethers.formatUnits(usdcBalBefore,6));
    console.log("Eth Balance before swap:", ethers.formatEther(ethBalanceBefore));

    const tx = await ROUTER.swapTokensForExactETH(
    amountOut,
    amountInMax,
    addresses,
    impersonatedSigner,
    deadline
  )

  await tx.wait();

   const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
 const ethBalanceAfter = await ethers.provider.getBalance(impersonatedSigner);
  console.log("=================After========================================");
  console.log("USDC Balance after swap:", ethers.formatUnits(usdcBalAfter, 6));
  console.log("Eth Balance after swap:", ethers.formatEther(ethBalanceAfter));


  console.log("Swapped successfully!");
  console.log("=========================================================");
  const usdcspent = usdcBalAfter - usdcBalAfter   ;
  const Ethreceived =   ethBalanceAfter - ethBalanceBefore    ;

  console.log("USDC spent:", ethers.formatUnits(usdcspent, 6));
  console.log("ETH receieved:", ethers.formatUnits(Ethreceived, 18));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

