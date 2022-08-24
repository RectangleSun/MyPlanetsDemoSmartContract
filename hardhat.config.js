require("@nomicfoundation/hardhat-toolbox");


require("@nomiclabs/hardhat-etherscan");
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0"
      },
      {
        version: "0.8.1"
      },
      {
        version: "0.7.0"
      },
      {
        version: "0.5.16"
      },
      {
        version: "0.6.6"
      },
      {
        version: "0.8.4"
      },
      {
        version: "0.8.14"
      },
      {
        version: "0.8.9"
      },
      
    ]
  },
  networks: {
    tbsc: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545	",
      accounts:
        ["0xa92fff97fe3c67707ee39afd82d7e6d827e07d25a286cb3ea333ad844798f767"],
    },
    mbsc: {
      url: "https://bsc-dataseed2.ninicoin.io",
      accounts:
        ["0xa92fff97fe3c67707ee39afd82d7e6d827e07d25a286cb3ea333ad844798f767"],
    },
  },
  etherscan: {
    apiKey: "BM52PMWGB669ARX8I86JAQUSQMDV5PJHZ1",
  },
};
