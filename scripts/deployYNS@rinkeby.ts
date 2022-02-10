import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const hre = require("hardhat");
// eslint-disable-next-line node/no-extraneous-require
const namehash = require("eth-ens-namehash");
const tld = "yak";
const ethers = hre.ethers;
const utils = ethers.utils;
const labelhash = (label: string) => utils.keccak256(utils.toUtf8Bytes(label));
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_HASH =
  "0x0000000000000000000000000000000000000000000000000000000000000000";
async function main() {
  const ENSRegistry = await ethers.getContractFactory("ENSRegistry");
  const FIFSRegistrar = await ethers.getContractFactory("FIFSRegistrar");
  const ReverseRegistrar = await ethers.getContractFactory("ReverseRegistrar");
  const PublicResolver = await ethers.getContractFactory("PublicResolver");
  const signers = await ethers.getSigners();
  const accounts = signers.map((s: SignerWithAddress) => s.address);
  const ens = await ENSRegistry.deploy();
  await ens.deployed();
  console.log("ens: ", ens.address); // 0x8A789CC874C89BCE9bf5B0f909752196d8CfE830
  const resolver = await PublicResolver.deploy(ens.address, ZERO_ADDRESS);
  await resolver.deployed();
  console.log("resolver: ", resolver.address); // 0x92ABfC191362ADa53f37104Ce9D9DB5A59a3d14b
  await setupResolver(ens, resolver, accounts);
  console.log("namehash: ", namehash.hash(tld)); // 0xabf11df72c3ff78aa82ec8e802807315c444ccd13be1a446b7b15aee3a913e4e
  const registrar = await FIFSRegistrar.deploy(ens.address, namehash.hash(tld));
  await registrar.deployed();
  console.log("registrar: ", registrar.address); // 0xaCAf3212Cf678c9BfBf8050A73E26752E8Acea80
  await setupRegistrar(ens, registrar);
  const reverseRegistrar = await ReverseRegistrar.deploy(
    ens.address,
    resolver.address
  );
  await reverseRegistrar.deployed();
  console.log("reverseRegistrar: ", reverseRegistrar.address); // 0x314e46Ee3f5519f6f159A2962bc8e36794d73700
  await setupReverseRegistrar(ens, registrar, reverseRegistrar, accounts);
}
// @ts-ignore
async function setupResolver(ens, resolver, accounts) {
  const resolverNode = namehash.hash("resolver");
  const resolverLabel = labelhash("resolver");
  await ens.setSubnodeOwner(ZERO_HASH, resolverLabel, accounts[0]);
  await ens.setResolver(resolverNode, resolver.address);
  await resolver["setAddr(bytes32,address)"](resolverNode, resolver.address);
}
// @ts-ignore
async function setupRegistrar(ens, registrar) {
  await ens.setSubnodeOwner(ZERO_HASH, labelhash(tld), registrar.address);
}
async function setupReverseRegistrar(
  // @ts-ignore
  ens,
  // @ts-ignore
  registrar,
  // @ts-ignore
  reverseRegistrar,
  // @ts-ignore
  accounts
) {
  await ens.setSubnodeOwner(ZERO_HASH, labelhash("reverse"), accounts[0]);
  await ens.setSubnodeOwner(
    namehash.hash("reverse"),
    labelhash("addr"),
    reverseRegistrar.address
  );
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  // eslint-disable-next-line no-process-exit
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    // eslint-disable-next-line no-process-exit
    process.exit(1);
  });
