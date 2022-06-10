
const { ethers } = require("hardhat");

async function main() {
  const MultiTransfer = await ethers.getContractFactory("MultiTransfer");
  const multiTransfer = await MultiTransfer.deploy();

  await multiTransfer.deployed();

  console.log("Contract deployed to:", multiTransfer.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
