
const { ethers, upgrades } = require("hardhat");

async function main() {
  const EnergyNFT = await ethers.getContractFactory("EnergyNFT");
  const eNFT = await upgrades.deployProxy(EnergyNFT, [], {
    initializer: "initialize",
  });

  await eNFT.deployed();

  console.log("Greeter deployed to:", eNFT.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
