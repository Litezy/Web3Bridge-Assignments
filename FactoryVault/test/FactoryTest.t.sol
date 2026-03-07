// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/interfaces/IFVault.sol";
import "src/interfaces/IVault.sol";
import "src/Factory.sol";
import "src/TokenVault.sol";
import "src/VaultNFT.sol";
import "src/interfaces/IERC20.sol";

contract FactoryTest is Test {
    Factory factory;
    VaultNFT nft;

    // real mainnet token addresses
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // whale addresses
    address usdcWhale = 0xf584F8728B874a6a5c7A8d4d387C9aae9172D621;
    address daiWhale = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
    address wethWhale = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;

    address user = makeAddr("user");

    function InitialContractFunding() private {
        address predicted = factory.computeVaultAddress(USDC);
        // fund it before deployment
        vm.startPrank(usdcWhale);
        IERC20(USDC).transfer(predicted, 1000e6);
        vm.stopPrank();
    }

    function setUp() public {
        // get our url from env to fork mainnet
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        // deploy factory
        factory = new Factory();

        // get nft contract from factory
        nft = VaultNFT(factory.getNFTAddress());
    }

    // ── helper to fund user with tokens
    function _fundUser(address token, address whale, uint256 amount) internal {
        vm.startPrank(whale);
        IERC20(token).transfer(user, amount);
        vm.stopPrank();
    }

    // Test 1, to deploy vault for USDC
    function testDeployUSDCVault() public {
        InitialContractFunding();
        address vaultAddress = factory.deployVault(USDC);
        console.log("USDC Vault deployed at:", vaultAddress);

        // vault should be stored in factory
        assertEq(factory.getVault(USDC), vaultAddress);
        assertTrue(vaultAddress != address(0));
    }

    // Test 2, deploy vault for DAI
    function testDeployDAIVault() public {
        InitialContractFunding();
        address vaultAddress = factory.deployVault(DAI);

        console.log("DAI Vault deployed at:", vaultAddress);
        assertEq(factory.getVault(DAI), vaultAddress);
    }

    // ── Test 3: cant deploy same vault twice
    function testCannotDeployDuplicateVault() public {
        factory.deployVault(USDC);
        vm.expectRevert("Vault already exists for this token");
        factory.deployVault(USDC);
    }

    // ── Test 4: NFT minted on vault deployment
    function testNFTMintedOnDeployment() public {
        address vaultAddress = factory.deployVault(USDC);

        uint256 nftBalance = nft.balanceOf(vaultAddress);
        assertEq(nftBalance, 1);
        console.log("NFT minted successfully, tokenId:", nft.tokenIdCounter());
    }

    // ── Test 5: deposit USDC into vault
    function testDepositUSDC() public {
        // deploy vault first
        address vaultAddress = factory.deployVault(USDC);

        // fund user with USDC from whale
        _fundUser(USDC, usdcWhale, 1000e6);

        // user approves vault and deposits
        vm.startPrank(user);
        IERC20(USDC).approve(vaultAddress, 1000e6);
        IVault(vaultAddress).deposit(1000e6);
        vm.stopPrank();

        // check balances
        assertEq(IVault(vaultAddress).getBalance(user), 1000e6);
        assertEq(IVault(vaultAddress).totalDeposits(), 1000e6);

        console.log("USDC deposited:", IVault(vaultAddress).getBalance(user));
    }

    // Test 6: withdraw USDC from vault
    function testWithdrawUSDC() public {
        address vaultAddress = factory.deployVault(USDC);
        _fundUser(USDC, usdcWhale, 1000e6);

        // deposit first
        vm.startPrank(user);
        IERC20(USDC).approve(vaultAddress, 1000e6);
        IVault(vaultAddress).deposit(1000e6);

        uint256 balanceBefore = IERC20(USDC).balanceOf(user);

        // withdraw
        IVault(vaultAddress).withdraw(500e6);
        vm.stopPrank();

        uint256 balanceAfter = IERC20(USDC).balanceOf(user);

        uint256 tokenId = nft.tokenIdCounter();
        string memory uri = nft.tokenURI(tokenId);
        emit log_string(uri);

        assertEq(balanceAfter - balanceBefore, 500e6);
        assertEq(IVault(vaultAddress).getBalance(user), 500e6);
        assertEq(IVault(vaultAddress).getVaultBalance(), 500e6);

        console.log("USDC withdrawn successfully");
    }

    // ── Test 7: tokenURI returns valid base64 ─────────────────────
    function testTokenURI() public {
        factory.deployVault(USDC);

        uint256 tokenId = nft.tokenIdCounter();
        string memory uri = nft.tokenURI(tokenId);

        console.log("tokenURI:", uri);

        // check it starts with data:application/json;base64,
        assertTrue(bytes(uri).length > 0);
    }

    // ── Test 8: compute vault address matches deployed ────────────
    function testComputeVaultAddress() public {
        address predicted = factory.computeVaultAddress(USDC);
        address deployed = factory.deployVault(USDC);

        console.log("Predicted:", predicted);
        console.log("Deployed: ", deployed);

        assertEq(predicted, deployed);
    }

    // ── Test 9: multiple vaults different tokens
    function testMultipleVaults() public {
        address usdcVault = factory.deployVault(USDC);
        address daiVault = factory.deployVault(DAI);
        address wethVault = factory.deployVault(WETH);

        // all different addresses
        assertTrue(usdcVault != daiVault);
        assertTrue(daiVault != wethVault);
        assertTrue(usdcVault != wethVault);

        // NFT counter should be 3
        assertEq(nft.tokenIdCounter(), 3);

        console.log("USDC Vault:", usdcVault);
        console.log("DAI Vault: ", daiVault);
        console.log("WETH Vault:", wethVault);
    }
}
