import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("MyERC20", function () {
  async function deployERC20() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, spender] = await hre.ethers.getSigners();

    const ERC20Contract = await hre.ethers.getContractFactory("MyERC20");
    const erc20Contract = await ERC20Contract.deploy(100000000n);
    erc20Contract.waitForDeployment();

    return { erc20Contract, owner, otherAccount, spender };
  }

  const DeployerFactory = async (funcName: string, owner: boolean = false) => {
    const { erc20Contract } = await loadFixture(deployERC20);
    let functionIdentifier;
    if (owner) {
      let [_owner] = await hre.ethers.getSigners();
      functionIdentifier = await (erc20Contract as any)[funcName](_owner.address);
      return { functionIdentifier, _owner }
    } else {
      functionIdentifier = await (erc20Contract as any)[funcName]()
      return functionIdentifier
    }
  };



  describe("Deployment", function () {
    it("Should get token balance", async function () {
      const { functionIdentifier: balance } = await DeployerFactory('balanceOf', true)
      expect(balance).to.equal(100000000);
      console.log('Token balance', balance)
    });


    it("Should get token symbol", async function () {
      // const symbol = await DeployerFactory('symbol');
      const { erc20Contract } = await loadFixture(deployERC20)
      // const ercContract = await (await loadFixture(deployERC20)).erc20Contract
      let symbol = await erc20Contract.symbol()
      expect(symbol).to.equal("CXIV")
      console.log('Token symbol', symbol)
    });

    it("Should get token name", async function () {
      const tokenName = await DeployerFactory('name')
      expect(tokenName).to.equal("WEB3CXIV")
      console.log('Token name', tokenName)
    });


    it("Should get token decimals", async function () {
      const decimal = await DeployerFactory('decimals')
      expect(decimal).to.equal(18)
      console.log('Token decimal', decimal)
    });

    it("Should get totalsupply", async function () {
      const totalsupply = await DeployerFactory('totalSupply')
      expect(totalsupply).to.equal(100000000n)
      console.log('Token totalsupply', totalsupply)
    });

    it("Should permit approval", async function () {
      const { owner, spender, erc20Contract } = await loadFixture(deployERC20);
      let value = 100
      await erc20Contract.approve(spender.address, value)
      const allowance = await erc20Contract.allowance(owner.address, spender.address);
      expect(allowance).to.equal(value);
      expect(owner.address).not.equal(spender.address);
    })


    it("Should transfer", async function () {
      const { owner, spender, erc20Contract } = await loadFixture(deployERC20);
      let value = 100
      const balanceOfOwnerBefore = await erc20Contract.balanceOf(owner.address)
      const balanceOfSpenderBefore = await erc20Contract.balanceOf(spender.address)
      await erc20Contract.transfer(spender.address, value);
      const balanceOfOwnerAfter = await erc20Contract.balanceOf(owner.address)
      const balanceOfSpenderAfter = await erc20Contract.balanceOf(owner.address)

      expect(balanceOfOwnerBefore).not.equal(balanceOfOwnerAfter);
      expect(balanceOfSpenderAfter).not.equal(balanceOfSpenderBefore);
      const OwnerChange = balanceOfOwnerBefore - balanceOfOwnerAfter;
      const SpenderChange = balanceOfSpenderAfter - balanceOfSpenderBefore;
      expect(OwnerChange).to.equal(value)
      expect(SpenderChange + BigInt(value)).to.equal(balanceOfOwnerBefore)
      // console.log(SpenderChange)
    })

    it("Should transfer from", async function () {
      const { owner, spender, erc20Contract } = await loadFixture(deployERC20);
      let value = 100
      const ownerBeforeBalance = await erc20Contract.balanceOf(owner.address)
      console.log("Owner Before balance", ownerBeforeBalance)
      await erc20Contract.approve(spender.address, value)
      const allowance = await erc20Contract.allowance(owner.address, spender.address);
      console.log("Allowance amount", allowance)
      expect(allowance).to.equal(value);
      expect(owner.address).not.equal(spender.address);

      const fromBalance = await erc20Contract.balanceOf(owner.address)
      await erc20Contract.connect(spender).transferFrom(owner.address, spender.address, value); // ✅
      const balanceOfOwnerAfter = await erc20Contract.balanceOf(owner.address);
      expect(fromBalance).not.equal(balanceOfOwnerAfter)

    })
  });




})