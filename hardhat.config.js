require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
  networks: {
    hardhat: {},
    ethereum: { url: process.env.ETH_RPC_URL || "", accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [] },
    arbitrum: { url: "https://arb1.arbitrum.io/rpc", accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [] },
    base: { url: "https://mainnet.base.org", accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [] },
  },
};
