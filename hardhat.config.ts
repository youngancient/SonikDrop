import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

// configure contract to be deployed on multichains
// OP chains: Lisk, Sepolia, Optimism, Base
// EVM compatible like: BSC, Rootstock

const config: HardhatUserConfig = {
  solidity: "0.8.24",
};

export default config;
