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
  const Rewards = await ethers.getContractFactory("YakYakRewards");
  const rewards = await Rewards.deploy();
  await rewards.deployed();
  console.log("YakYak Rewards deployed to:", rewards.address);
  // YakYak® Rewards: 0xC9F51064022A011152B7dA6dDE44def02b5C157C
  const Bank = await ethers.getContractFactory("YakYakBank");
  const bank = await Bank.deploy(rewards.address);
  await bank.deployed();
  console.log("YakYak Bank deployed to:", bank.address);
  // const YakYakMe = await ethers.getContractFactory("YakYakMe");
  // const yakYakMe = await YakYakMe.deploy();
  // await yakYakMe.deployed();
  // console.log("YakYakMe deployed to:", yakYakMe.address);
  // YakYak® Me: 0x756276F1a5c2DD4ba49c54CcC7729fE0D9d10968
  // YakYak® Bank: 0xBedf7Ecd022be10b4e13B7AFD29CD5fEdEc474ab
  const Yaklon = await ethers.getContractFactory("YakYakClone");
  const clone = await Yaklon.deploy(rewards.address);
  await clone.deployed();
  console.log("YakYak Clone deployed to:", clone.address);
  // YakYakClone deployed to: 0xa671cb8644Bb622737f33FF4Fe98A6EA4987480c
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
