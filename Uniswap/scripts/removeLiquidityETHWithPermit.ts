import { ethers } from "hardhat";
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const main = async () => {
  const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const FACTORY_ADDRESS = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
  const TokenHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

  const [wallet] = await ethers.getSigners();

  await helpers.impersonateAccount(TokenHolder);
  const whale = await ethers.getSigner(TokenHolder);

  const USDC_whale = await ethers.getContractAt("IERC20", USDCAddress, whale);
  await USDC_whale.transfer(wallet.address, ethers.parseUnits("5000", 6));
  await whale.sendTransaction({ to: wallet.address, value: ethers.parseEther("10") });

  const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, wallet);
  const USDC = await ethers.getContractAt("IERC20", USDCAddress, wallet);
  const FACTORY = await ethers.getContractAt("IUniswapV2Factory", FACTORY_ADDRESS, wallet);

  const pairAddress = await FACTORY.getPair(USDCAddress, WETHAddress);
  const LP = await ethers.getContractAt("IUniswapV2Pair", pairAddress, wallet);

  const token0 = await LP.token0();
  const { reserve0, reserve1 } = await LP.getReserves();

  const [reserveUSDC, reserveWETH] =
    token0.toLowerCase() === USDCAddress.toLowerCase()
      ? [BigInt(reserve0), BigInt(reserve1)]
      : [BigInt(reserve1), BigInt(reserve0)];

  const amountTokenDesired = ethers.parseUnits("1000", 6);
  const amountETHDesired = (amountTokenDesired * reserveWETH) / reserveUSDC;
  const amountTokenMin = (amountTokenDesired * 99n) / 100n;
  const amountETHMin = (amountETHDesired * 99n) / 100n;
  const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

  await USDC.approve(UNIRouter, amountTokenDesired);

  const usdcBefore = await USDC.balanceOf(wallet.address);
  const ethBefore = await ethers.provider.getBalance(wallet.address);

  console.log("=================Before========================================");
  console.log("USDC Balance:", ethers.formatUnits(usdcBefore, 6));
  console.log("ETH Balance:", ethers.formatUnits(ethBefore, 18));

  const addTx = await ROUTER.addLiquidityETH(
    USDCAddress, amountTokenDesired, amountTokenMin, amountETHMin,
    wallet.address, deadline, { value: amountETHDesired }
  );
  await addTx.wait();

  const lpBalance = BigInt(await LP.balanceOf(wallet.address));
  console.log("LP tokens received:", ethers.formatUnits(lpBalance, 18));

  // ── Reconstruct permit digest manually using the pair's own DOMAIN_SEPARATOR ──
  // Uniswap V2 pairs don't follow standard EIP-712 domain (no version field)
  // So we read DOMAIN_SEPARATOR directly from the contract and sign the raw digest

  const DOMAIN_SEPARATOR = await LP.DOMAIN_SEPARATOR();
  const nonce = BigInt(await LP.nonces(wallet.address));

  const PERMIT_TYPEHASH = ethers.keccak256(
    ethers.toUtf8Bytes(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    )
  );

  // Encode the permit struct hash
  const structHash = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "address", "address", "uint256", "uint256", "uint256"],
      [PERMIT_TYPEHASH, wallet.address, UNIRouter, lpBalance, nonce, deadline]
    )
  );

  // Build the final EIP-712 digest using the pair's DOMAIN_SEPARATOR directly
  const digest = ethers.keccak256(
    ethers.concat([
      ethers.toUtf8Bytes("\x19\x01"),
      DOMAIN_SEPARATOR,
      structHash,
    ])
  );

  // Sign the raw digest (not typed data — bypasses domain reconstruction)
  const signingKey = new ethers.SigningKey(
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" // Hardhat account #0 private key
  );
  const sig = signingKey.sign(digest);
  const { v, r, s } = sig;

  // ── Recalculate removal mins ──────────────────────────────────────
  const { reserve0: r0, reserve1: r1 } = await LP.getReserves();
  const totalSupply = BigInt(await LP.totalSupply());

  const [updatedReserveUSDC, updatedReserveWETH] =
    token0.toLowerCase() === USDCAddress.toLowerCase()
      ? [BigInt(r0), BigInt(r1)]
      : [BigInt(r1), BigInt(r0)];

  const expectedUSDC = (lpBalance * updatedReserveUSDC) / totalSupply;
  const expectedETH = (lpBalance * updatedReserveWETH) / totalSupply;
  const removeUSDCMin = (expectedUSDC * 99n) / 100n;
  const removeETHMin = (expectedETH * 99n) / 100n;

  console.log("Expected USDC back:", ethers.formatUnits(expectedUSDC, 6));
  console.log("Expected ETH back:", ethers.formatUnits(expectedETH, 18));

  const removeTx = await ROUTER.removeLiquidityETHWithPermit(
    USDCAddress, lpBalance, removeUSDCMin, removeETHMin,
    wallet.address, deadline,
    false, v, r, s
  );
  await removeTx.wait();

  const usdcAfter = await USDC.balanceOf(wallet.address);
  const ethAfter = await ethers.provider.getBalance(wallet.address);

  console.log("\n=================After========================================");
  console.log("USDC Balance:", ethers.formatUnits(usdcAfter, 6));
  console.log("ETH Balance:", ethers.formatUnits(ethAfter, 18));
  console.log("Liquidity removed with permit successfully! ✅");
  console.log("=========================================================");
  console.log("USDC received back:", ethers.formatUnits( usdcBefore - usdcAfter, 6));
};

main().catch(console.error);