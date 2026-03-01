const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const USDCHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

    await helpers.impersonateAccount(USDCHolder);
    const impersonatedSigner = await ethers.getSigner(USDCHolder);

    const amountIn = ethers.parseUnits("1000", 6);
    const addresses = [USDCAddress, DAIAddress];
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

    await USDC.approve(UNIRouter,amountIn);
    // check balance
    const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
    const daiBalBefore = await DAI.balanceOf(impersonatedSigner.address);
    console.log(
        "=================Before========================================",
    );
    console.log("USDC Balance before swap:", ethers.formatUnits(usdcBalBefore,6));
    console.log("Dai Balance before swap:", ethers.formatUnits(daiBalBefore,18));

    const tx = await ROUTER.swapExactTokensForTokens(
    amountIn,
    0n,
    addresses,
    impersonatedSigner,
    deadline
  )

  await tx.wait();

   const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
  const daiBalAfter = await DAI.balanceOf(impersonatedSigner.address);
  // const wethBalAfter = await WETH.balanceOf(impersonatedSigner.address);
  console.log("=================After========================================");
  console.log("USDC Balance after swap:", ethers.formatUnits(usdcBalAfter, 6));
  console.log("Dai Balance after swap:", ethers.formatUnits(daiBalAfter, 18));


  console.log("Swapped successfully!");
  console.log("=========================================================");
  const usdcUsed = usdcBalBefore - usdcBalAfter;
  const daiReceived =  daiBalAfter - daiBalBefore  ;

  console.log("USDC Used:", ethers.formatUnits(usdcUsed, 6));
  console.log("DAI Balance after swap:", ethers.formatUnits(daiReceived, 18));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});