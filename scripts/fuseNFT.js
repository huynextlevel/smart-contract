
const { ethers, upgrades } = require("hardhat");

async function main() {
  const FuseNFT = await ethers.getContractFactory("FuseNFT");
  const fuseNFT = await upgrades.deployProxy(FuseNFT, [], {
    initializer: "initialize",
  });

  await fuseNFT.deployed();

  console.log("Contract deployed to:", fuseNFT.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
