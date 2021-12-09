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
  const YakYakPoints = await ethers.getContractFactory("YakYakPoints");
  const yakYakPoints = await YakYakPoints.deploy();
  await yakYakPoints.deployed();
  console.log("yakYakPoints deployed to:", yakYakPoints.address);
  // yakYakPoints deployed to: 0x4884e8a09Ab8a6B494AF88adB55C1ba30CCD3EB2
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
