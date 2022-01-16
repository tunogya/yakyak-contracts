// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";

async function main() {
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
  const Bank = await ethers.getContractFactory("YakYakBank");
  const bank = await Bank.deploy(rewards.address);
  await bank.deployed();
  console.log("YakYak Bank deployed to:", bank.address);
  const Yaklon = await ethers.getContractFactory("Yaklon");
  const clone = await upgrades.deployProxy(
    Yaklon,
    [rewards.address, "https://yakyak.wakanda-labs.com/"],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  await clone.deployed();
  console.log("YakYak Clone deployed to:", clone.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
