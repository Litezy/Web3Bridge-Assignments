import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("SaveAssets", function () {
    async function deployAssets() {
        // Contracts are deployed using the first signer/account by default
        const [owner] = await hre.ethers.getSigners();
        const ERC20Contract = await hre.ethers.getContractFactory("MyERC20");
        const erc20Contract = await ERC20Contract.deploy(1000000n);

        const AssetsContract = await hre.ethers.getContractFactory("SaveAssets");
        const assetsContract = await AssetsContract.deploy(erc20Contract.target);
        assetsContract.waitForDeployment();

        return { assetsContract, owner, erc20Contract };
    }

    describe("Deployment", async function () {

        it("Should get wallet balance", async function () {
            const { owner, erc20Contract } = await loadFixture(deployAssets)
            const balance = await erc20Contract.balanceOf(owner.address)
            expect(balance).to.equal(1000000n)
        })


        it("Should get contract balance", async function () {
            const { erc20Contract } = await loadFixture(deployAssets)
            const contractBal = await erc20Contract.balanceOf(erc20Contract.target);
            expect(contractBal).to.equal(1000000n)
        })

        it("Should deposit ether", async function () {
            const { assetsContract } = await loadFixture(deployAssets);

            const amount = hre.ethers.parseEther("1.0");

            await assetsContract.depositEther({ value: amount });

            const balance = await hre.ethers.provider.getBalance(assetsContract.target);
            expect(balance).to.equal(amount);
        });

        it("Should deposit ERC20 token", async function () {
            const { assetsContract, owner, erc20Contract } = await loadFixture(deployAssets);

            const amount = 100n;

            await erc20Contract.approve(assetsContract.target, amount);
            const allowance = await erc20Contract.allowance(owner.address, assetsContract.target);
            expect(allowance).to.equal(amount);
            await assetsContract.depositErc20(erc20Contract.target, amount);

            const contractTokenBalance = await erc20Contract.balanceOf(assetsContract.target);
            expect(contractTokenBalance).to.equal(amount);
        });

        it("Should withdraw ETH", async function () {
            const { assetsContract, owner } = await loadFixture(deployAssets);
            const amount = hre.ethers.parseEther("1.0");

            // deposit first
            await assetsContract.depositEther({ value: amount });

            const ownerBalanceBefore = await hre.ethers.provider.getBalance(owner.address);

            await assetsContract.withdrawEther(amount);

            const ownerBalanceAfter = await hre.ethers.provider.getBalance(owner.address);

            expect(ownerBalanceAfter).greaterThan(ownerBalanceBefore);

            const contractBalance = await hre.ethers.provider.getBalance(assetsContract.target);
            expect(contractBalance).to.equal(0n);
        });

        it("Should withdraw ERC20 token", async function () {
            const { assetsContract, owner, erc20Contract } = await loadFixture(deployAssets);
            const amount = 100n;

            // approve and deposit first
            await erc20Contract.approve(assetsContract.target, amount);
            await assetsContract.depositErc20(erc20Contract.target, amount);

            const ownerBalanceBefore = await erc20Contract.balanceOf(owner.address);

            await assetsContract.withdrawErc20(erc20Contract.target, amount);

            const ownerBalanceAfter = await erc20Contract.balanceOf(owner.address);

            // owner should have gotten tokens back
            expect(ownerBalanceAfter - ownerBalanceBefore).to.equal(amount);

            // contract should have no tokens left
            const contractBalance = await erc20Contract.balanceOf(assetsContract.target);
            expect(contractBalance).to.equal(0n);
        });
    })
});