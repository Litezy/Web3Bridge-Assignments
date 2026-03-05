const { ethers } = require("hardhat");

const main = async () => {
  // deploy factory first
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await Factory.deploy();
  await factory.waitForDeployment();
  console.log("Factory deployed to:", await factory.getAddress());

  // deploy child through factory
  const owner = "0xdead";
  const value = 100;

  const tx = await factory.deploy(owner, value);
  await tx.wait();

  // get all deployed children
  const children = await factory.getDeployedChildren();
  console.log("Deployed children:", children);
};

main().catch(console.error);