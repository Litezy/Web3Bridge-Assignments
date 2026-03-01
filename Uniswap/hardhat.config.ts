import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      forking: {
        url: process.env.ETH_RPC!,
        blockNumber: 24557497,
      },
      gasPrice: "auto",
      initialBaseFeePerGas: 0,
    },
  },
};
export default config;