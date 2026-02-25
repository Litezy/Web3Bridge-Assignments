import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("Multisig", function () {
    async function deployMultisigContract() {
        // Contracts are deployed using the first signer/account by default
        const [owner1, owner2, owner3, owner4, owner5, owner6, nonOwner] = await hre.ethers.getSigners();

        const MultisigContract = await hre.ethers.getContractFactory("Multisig");
        const multisigContract = await MultisigContract.deploy();
        multisigContract.waitForDeployment();

        return { owner1, owner2, owner3, owner4, owner5, owner6, nonOwner, multisigContract };
    }

    describe("Transactions", async function () {
        it("Should should populate 5 owners", async function () {
            const { owner2, owner3, owner4, owner5, multisigContract } = await loadFixture(deployMultisigContract)
            await multisigContract.connect(owner2).makeOwner()
            await multisigContract.connect(owner3).makeOwner()
            await multisigContract.connect(owner4).makeOwner()
            await multisigContract.connect(owner5).makeOwner()

        })


        it("Should revert for 6th owner", async function () {
            const { owner2, owner3, owner4, owner5, owner6, multisigContract } = await loadFixture(deployMultisigContract)
            await multisigContract.connect(owner2).makeOwner()
            await multisigContract.connect(owner3).makeOwner()
            await multisigContract.connect(owner4).makeOwner()
            await multisigContract.connect(owner5).makeOwner()
            // should fail owner 6
            expect(await multisigContract.connect(owner6).makeOwner()).to.be.revertedWith("Owners are filled, no room for more");

        })

        it("should allow only owners to deposit ether", async function () {
            const { multisigContract, owner1, owner2, nonOwner } = await loadFixture
                (deployMultisigContract);

            // owner depsit
            await expect(multisigContract.connect(owner1).depositEther({ value: hre.ethers.parseEther("1") })).to.not.be.reverted;

            // non owner deposit
            await expect(
                multisigContract.connect(nonOwner).depositEther({ value: hre.ethers.parseEther("1") })
            ).to.be.revertedWith("Only owner can deposit");
        });

        it("should create a transaction and auto-approve creator", async function () {
            const { multisigContract, owner1, owner6 } = await loadFixture(deployMultisigContract);

            const amount = hre.ethers.parseEther("0.5");

            await multisigContract.connect(owner1).createATransaction(owner6.address, amount);

            const tx = await multisigContract.getOneTransaction(1);

            expect(tx.to).to.equal(owner6.address);
            expect(tx.value).to.equal(amount);
            expect(tx.approvals).to.equal(1);
        });


        it("should revert if non-owner creates transaction", async function () {
            const { multisigContract, nonOwner, owner1 } = await loadFixture(deployMultisigContract);

            await expect(
                multisigContract.connect(nonOwner).createATransaction(owner1.address, 100)
            ).to.be.revertedWith("Only owner can create a transaction");
        });

        it("should fetch a transaction by id", async function () {
            const { multisigContract, owner1, owner2 } = await loadFixture(deployMultisigContract);

            await multisigContract.connect(owner1).createATransaction(owner2.address, 100);

            const tx = await multisigContract.getOneTransaction(0);

            expect(tx.id).to.be.revertedWith("Invalid Transaction Id");
        });

        it("should revert for invalid transaction id", async function () {
            const { multisigContract } = await loadFixture(deployMultisigContract);

            await expect(
                multisigContract.getOneTransaction(1)
            ).to.be.revertedWith("Invalid Transaction Id");
        });


        it("should allow another owner to approve transaction", async function () {
            const { multisigContract, owner1, owner2 } = await loadFixture(deployMultisigContract);

            await multisigContract.connect(owner1).createATransaction(owner2.address, 100);

            await expect(
                multisigContract.connect(owner2).approveTransaction(1)
            ).to.not.be.reverted;

            const tx = await multisigContract.getOneTransaction(1);
            expect(tx.approvals).to.equal(2);
        });


        it("should prevent double approval", async function () {
            const { multisigContract, owner1, owner2 } = await loadFixture(deployMultisigContract);

            await multisigContract.connect(owner1).createATransaction(owner2.address, 100);

            await multisigContract.connect(owner2).approveTransaction(0);

            await expect(
                multisigContract.connect(owner2).approveTransaction(0)
            ).to.be.revertedWith("You have already approved this transaction");
        });


        it("should execute transaction only when threshold is reached", async function () {
            const { multisigContract, owner1, owner2, owner3 } = await loadFixture(deployMultisigContract);

            // Deposit ether first
            await multisigContract.connect(owner1).depositEther({ value: hre.ethers.parseEther("1") });

            const recipient = owner3.address;
            const amount = hre.ethers.parseEther("0.5");

            // Owner1 creates a transaction
            await multisigContract.connect(owner1).createATransaction(recipient, amount);

            const balanceBefore = await hre.ethers.provider.getBalance(recipient);

            // 2nd approval by owner2 (transaction should NOT execute yet)
            await multisigContract.connect(owner2).approveTransaction(1);

            let tx = await multisigContract.getOneTransaction(1);
            expect(tx.executed).to.equal(false); // still not executed
            let balanceMid = await hre.ethers.provider.getBalance(recipient);
            expect(balanceMid).to.equal(balanceBefore); // balance unchanged

            // 3rd approval by owner3 triggers execution
            await multisigContract.connect(owner3).approveTransaction(1);

            tx = await multisigContract.getOneTransaction(1);
            expect(tx.executed).to.equal(true); // now reached

            const balanceAfter = await hre.ethers.provider.getBalance(recipient);
            // expect(balanceAfter).to.be.gt(balanceBefore); // recipient received funds
        });




        it("should mark transaction as not executed if threshhold isn't reached", async function () {
            const { multisigContract, owner1, owner2 } = await loadFixture(deployMultisigContract);

            await multisigContract.connect(owner1).depositEther({ value: hre.ethers.parseEther("1") });

            await multisigContract.connect(owner1).createATransaction(owner2.address, 100);

            await multisigContract.connect(owner2).approveTransaction(1);

            const tx = await multisigContract.getOneTransaction(1);

            expect(tx.executed).to.equal(false);
        });

    })
});