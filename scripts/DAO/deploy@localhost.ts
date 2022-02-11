// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying account: ", await deployer.getAddress());
  console.log(
    "Deploying account balance: ",
    (await deployer.getBalance()).toString()
  );
  const Rewards = await ethers.getContractFactory("Rewards");
  const rewards = Rewards.attach("");
  const DAO = await ethers.getContractFactory("DAO");
  const dao = await upgrades.deployProxy(DAO, [rewards.address], {
    initializer: "initialize",
    kind: "uups",
  });
  await dao.deployed();
  console.log("DAO deployed to:", dao.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
