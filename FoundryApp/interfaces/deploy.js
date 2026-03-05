const { ethers } = require("ethers");

const deployChild = async () => {
  const Child = await ethers.getContractFactory("Child");
  const child = await Child.deploy(owner, value);
  await child.waitForDeployment();
  console.log("Child deployed to:", await child.getAddress());
};

deployChild().catch(console.error);