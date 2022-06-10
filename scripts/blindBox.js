
const { ethers, upgrades } = require("hardhat");

async function main() {
  const BlindBox = await ethers.getContractFactory("BlindBox");
  const blindBox = await upgrades.deployProxy(BlindBox, [], {
    initializer: "initialize",
  });

  await blindBox.deployed();

  console.log("Contract deployed to:", blindBox.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
