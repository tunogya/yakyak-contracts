// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Prepare to deploy
  const [deployer] = await ethers.getSigners();
  console.log("Deploying account:", await deployer.getAddress());
  console.log(
    "Deploying account balance:",
    (await deployer.getBalance()).toString(),
    "\n"
  );
  // const YakYakRewards = await ethers.getContractFactory("YakYakRewards");
  // const yakYakRewards = await YakYakRewards.deploy();
  // await yakYakRewards.deployed();
  // console.log("YakYak® Rewards deployed to:", yakYakRewards.address);
  // YakYak® Rewards: 0xC9F51064022A011152B7dA6dDE44def02b5C157C
  const YakYakBank = await ethers.getContractFactory("YakYakBank");
  const yakYakRewardAddress = "0xC9F51064022A011152B7dA6dDE44def02b5C157C";
  const yakYakBankName = "YakYakBank";
  const yakYakBankVersion = "1";
  const yakYakBankSalt =
    "0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558";
  const yakYakBank = await YakYakBank.deploy(
    yakYakRewardAddress,
    yakYakBankName,
    yakYakBankVersion,
    yakYakBankSalt
  );
  await yakYakBank.deployed();
  console.log("YakYak® Bank deployed to:", yakYakBank.address);
  // YakYak® Bank: 0x808c77D8125C2b5101B5bbAAEAdce04866CcB1b7
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
