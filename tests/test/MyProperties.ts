import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";


describe("MyProperties", function () {
    async function deployPropertyContract() {
        // Contracts are deployed using the first signer/account by default
        const [owner, buyer] = await hre.ethers.getSigners();

        const ERC20Contract = await hre.ethers.getContractFactory("MyERC20");
        const erc20Contract = await ERC20Contract.deploy(100000000n);

        const PropertyContract = await hre.ethers.getContractFactory("MyProperties");
        const propertyContract = await PropertyContract.deploy(erc20Contract.target);
        propertyContract.waitForDeployment();

        return { erc20Contract, owner, propertyContract, buyer, };
    }

    const payload = { amount: 200n, proptype: "Home", category: "Electronics", warranty: 2 }
    function etherInWei(_amount: bigint) {
        return _amount * 10n ** 18n;
    }


    describe("Deployment", async function () {
        it("Should create a property", async function () {
            const { owner, propertyContract } = await loadFixture(deployPropertyContract)
            const [deployer] = await hre.ethers.getSigners();
            expect(deployer.address).to.equal(owner.address)
            const ownerCall = propertyContract.connect(owner);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty)
            const property = await propertyContract.getProperty(1)
            expect(property.warranty).to.equal(payload.warranty)
            expect(property.category).to.equal(payload.category)
            expect(property.price).to.equal(etherInWei(payload.amount))
            expect(property.propType).to.equal(payload.proptype)

        })

        it("Should revert for invalid propertyId", async function () {
            const { owner, propertyContract } = await loadFixture(deployPropertyContract)
            const [deployer] = await hre.ethers.getSigners();
            expect(deployer.address).to.equal(owner.address)
            const ownerCall = propertyContract.connect(owner);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty)
            await expect(propertyContract.getProperty(0)).to.be.revertedWith("Property not found")

        })

        it("Should list a property as owner", async function () {
            const { owner, propertyContract } = await loadFixture(deployPropertyContract)
            const ownerCall = propertyContract.connect(owner);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty);
            await ownerCall.listProperty(1)
            const property = await propertyContract.getProperty(1)
            expect(property.isListed).to.be.equal(true)
        })

        it("Should revert if not owner of property", async function () {
            const { owner, propertyContract, buyer } = await loadFixture(deployPropertyContract)
            const ownerCall = propertyContract.connect(owner);
            const buyerCall = propertyContract.connect(buyer);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty);
            await expect(buyerCall.listProperty(1)).to.be.revertedWith("Not owner of this property")
            const property = await propertyContract.getProperty(1)
            expect(property.isListed).to.be.equal(false)
        })


        it("Should unlist a property as owner", async function () {
            const { owner, propertyContract } = await loadFixture(deployPropertyContract)
            const ownerCall = propertyContract.connect(owner);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty);
            await ownerCall.listProperty(1)
            const propertyList = await propertyContract.getProperty(1)
            expect(propertyList.isListed).to.be.equal(true)
            await ownerCall.unlistProperty(1)
            const propertyUnlist = await propertyContract.getProperty(1)
            expect(propertyUnlist.isListed).to.be.equal(false)
        })


        it("Should not unlist a property as non-owner", async function () {
            const { owner, propertyContract, buyer } = await loadFixture(deployPropertyContract)
            const ownerCall = propertyContract.connect(owner);
            const buyerCall = propertyContract.connect(buyer);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty);
            await ownerCall.listProperty(1)
            const propertyList = await propertyContract.getProperty(1)
            expect(propertyList.isListed).to.be.equal(true)
            await expect(buyerCall.unlistProperty(1)).to.be.revertedWith("Not owner of this property")
        })



        it("Should delete a property as owner", async function () {
            const { owner, propertyContract } = await loadFixture(deployPropertyContract)
            const ownerCall = propertyContract.connect(owner);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty);
            await ownerCall.deleteProperty(1);
            await expect(propertyContract.getProperty(1)).to.be.revertedWith("Property not found")
        })

        it("Should not delete a property as non-owner", async function () {
            const { owner, propertyContract, buyer } = await loadFixture(deployPropertyContract)
            const ownerCall = propertyContract.connect(owner);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty);
            await expect(propertyContract.connect(buyer).deleteProperty(1)).to.be.revertedWith("Not owner of this property");
        })

        it("Buyer should buy a property", async function () {
            const { owner, propertyContract, buyer, erc20Contract } = await loadFixture(deployPropertyContract)
            const ownerCall = propertyContract.connect(owner);
            const buyerCall = propertyContract.connect(buyer);
            await ownerCall.createProperty(payload.amount, payload.proptype, payload.category, payload.warranty);
            await ownerCall.listProperty(1)
            const propertyList = await propertyContract.getProperty(1)
            expect(propertyList.isListed).to.be.equal(true)

            const propertyBefore = await propertyContract.getProperty(1)
            // console.log(propertyBefore)

            // //buyer mints and buys the property
            await buyerCall.claimFaucet(buyer.address)
            const buyerBal = await erc20Contract.balanceOf(buyer.address)
            // console.log('Buyers bal',buyerBal)
            // 200000000000000000000n
            // 1000000000000000000000n
            expect(buyerBal).to.equal(1000000000000000000000n)
            //     // console.log(propertyBefore.price)
            await erc20Contract.connect(buyer).approve(propertyContract.target, propertyBefore.price);

            const allowance = await erc20Contract.allowance(buyer, propertyContract.target)
            // console.log("allowance", allowance);
            // console.log("property ", propertyBefore);
            await buyerCall.buyProperty(1)
            // // checks
            const propertyAfter = await propertyContract.getProperty(1)
            expect(propertyAfter.owner).not.equal(owner.address);
            const finalBuyerBal = await erc20Contract.balanceOf(buyer.address)
            const ownereBal = await erc20Contract.balanceOf(owner.address)
            expect(finalBuyerBal).to.equal(800000000000000000000n)
            expect(ownereBal).to.equal(200000000000100000000n)

        })

    })
});