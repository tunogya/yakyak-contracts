pragma solidity ^0.8.4;

import {INameWrapper, PublicResolver} from '@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol';
import '@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol';
import '@ensdomains/ens-contracts/contracts/registry/FIFSRegistrar.sol';
import {NameResolver, ReverseRegistrar} from '@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol';