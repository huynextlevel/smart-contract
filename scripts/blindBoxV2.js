
const { ethers, upgrades } = require("hardhat");

async function main() {
  const BlindBoxV2 = await ethers.getContractFactory("BlindBoxV2");
  const blindBoxV2 = await upgrades.deployProxy(BlindBoxV2, [], {
    initializer: "initialize",
  });

  await blindBoxV2.deployed();

  console.log("Contract deployed to:", blindBoxV2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
