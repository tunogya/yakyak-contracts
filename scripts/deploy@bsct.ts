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
  const YakYakRewards = await ethers.getContractFactory("YakYakRewards");
  const yakYakRewards = await YakYakRewards.deploy();
  await yakYakRewards.deployed();
  console.log("YakYak® Rewards deployed to:", yakYakRewards.address);
  // YakYak® Rewards: 0x6FAe74ffd4C8B45aBA1dE6329de162324Cd53D77
  const YakYakBank = await ethers.getContractFactory("YakYakBank");
  const yakYakRewardAddress = yakYakRewards.address;
  const yakYakBankSalt =
    "0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558";
  const yakYakBank = await YakYakBank.deploy(
    yakYakRewardAddress,
    yakYakBankSalt
  );
  await yakYakBank.deployed();
  console.log("YakYak® Bank deployed to:", yakYakBank.address);
  // YakYak® Bank: 0x3b2051DD08983fb3a6A867C8c628C03F013d8Bd5
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
