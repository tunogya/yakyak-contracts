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
  // const rewards = await Rewards.deploy();
  // await rewards.deployed();
  const rewards = Rewards.attach("0x424833e9D6ce14651aBf2B4C0f2fc0837301CaCb");
  console.log("YakYak Rewards deployed to:", rewards.address);
  const Bank = await ethers.getContractFactory("YakYakBank");
  // const bank = await Bank.deploy(rewards.address);
  // await bank.deployed();
  const bank = Bank.attach("0x7EA28C005bA5a06E0dcCc4863740632bd0ce8095");
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
  const DAO = await ethers.getContractFactory("YakYakDao");
  const dao = await upgrades.deployProxy(DAO, [rewards.address], {
    initializer: "initialize",
    kind: "uups",
  });
  await dao.deployed();
  console.log("YakYak Clone deployed to:", dao.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
