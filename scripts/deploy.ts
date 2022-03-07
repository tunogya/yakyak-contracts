// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import chalk from "chalk";
import { deploy1820 } from "deploy-eip-1820";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(chalk.dim("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"));
  console.log(chalk.dim("YakYak Contracts - Deploy Script"));
  console.log(chalk.dim("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"));
  console.log(chalk.dim("Deployer:"), await deployer.getAddress());
  await deploy1820(deployer);
  console.log(
    chalk.yellow("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
  );
  console.log(
    chalk.yellow("CAUTION: Deploying Prize Pool in a front-runnable way!")
  );
  console.log(chalk.cyan("\nDeploying MockYieldSource..."));
  const MockYieldSource = await ethers.getContractFactory("MockYieldSource");
  const mockYieldSource = await MockYieldSource.deploy("Yak", "YAK", 18);
  await mockYieldSource.deployed();
  console.log(chalk.green("mockYieldSource: ", mockYieldSource.address));
  console.log(chalk.cyan("\nDeploying YieldSourcePrizePool..."));
  const YieldSourceRewardsPool = await ethers.getContractFactory(
    "YieldSourcePrizePool"
  );
  const yieldSourcePrizePool = await YieldSourceRewardsPool.deploy(
    deployer,
    mockYieldSource.address
  );
  await yieldSourcePrizePool.deployed();
  console.log(
    chalk.green("yieldSourcePrizePool: ", yieldSourcePrizePool.address)
  );
  console.log(chalk.cyan("\nDeploying Pass..."));
  const Pass = await ethers.getContractFactory("Pass");
  const pass = await Pass.deploy(
    "Pass",
    "PASS",
    18,
    yieldSourcePrizePool.address
  );
  await pass.deployed();
  console.log(chalk.green("PassResult: ", pass.address));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
