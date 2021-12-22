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
  const yakYakBank = await YakYakBank.deploy(yakYakRewardAddress);
  await yakYakBank.deployed();
  console.log("YakYak® Bank deployed to:", yakYakBank.address);
  // YakYak® Bank: 0xBedf7Ecd022be10b4e13B7AFD29CD5fEdEc474ab
  // const PETH = await ethers.getContractFactory("PETH");
  // const peth = await PETH.deploy();
  // await peth.deployed();
  // console.log("PETH deployed to:", peth.address);
  // PETH deployed to: 0xbe155CDf7F6dA37684A36DCC02076Ed314d5467a
  // const PUSD = await ethers.getContractFactory("PUSD");
  // const pusd = await PUSD.deploy();
  // await pusd.deployed();
  // console.log("PUSD deployed to:", pusd.address);
  // PUSD deployed to: 0x7F037a1dF6F62B46Ede765c535187ECCeEF5D455
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
