import {
  time,
  loadFixture
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("ERC20", function () {
  async function deployERC20() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const ERC20Contract = await hre.ethers.getContractFactory("ERC20");
    const erc20Contract = await ERC20Contract.deploy(100000000n);
    erc20Contract.waitForDeployment();

    return { erc20Contract, owner, otherAccount };
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
      const symbol = await DeployerFactory('symbol');
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


  });




})