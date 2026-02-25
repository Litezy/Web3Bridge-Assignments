// import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
// import { expect } from "chai";
// import hre from "hardhat";

// describe("OceanProperties", function () {
//     async function deployPropertyContract() {
//         // Contracts are deployed using the first signer/account by default
//         const [owner, secondAccount, ] = await hre.ethers.getSigners();

//         const ERC20Contract = await hre.ethers.getContractFactory("ERC20");
//         const erc20Contract = await ERC20Contract.deploy(100000000n);

//         const PropertyContract = await hre.ethers.getContractFactory("OceanProperties");
//         const propertyContract = await PropertyContract.deploy(erc20Contract.target);
//         propertyContract.waitForDeployment();

//         return { erc20Contract, owner, propertyContract, secondAccount,  };
//     }

//     describe("Deployment", async function (){

//     })
// });