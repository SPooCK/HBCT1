const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();
var NonceTrackerSubprovider = require("web3-provider-engine/subproviders/nonce-tracker")

module.exports = {
  plugins: [
    'truffle-plugin-verify',
	  'truffle-contract-size'
  ],
  api_keys: {
    etherscan: 'SV3ZJPVTPTFAN3W7GIK5VUKSEYDC5HT2Q8'
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 97,
      gas: 10000000
      // optional config values:
      // gas
      // gasPrice
      // from - default address to use for any transaction Truffle makes during migrations
      // provider - web3 provider instance Truffle should use to talk to the Ethereum network.
      //          - function that returns a web3 provider instance (see below.)
      //          - if specified, host and port are ignored.
      // skipDryRun: - true if you don't want to test run the migration locally before the actual migration (default is false)
      // confirmations: - number of confirmations to wait between deployments (default: 0)
      // timeoutBlocks: - if a transaction is not mined, keep waiting for this number of blocks (default is 50)
      // deploymentPollingInterval: - duration between checks for completion of deployment transactions
      // disableConfirmationListener: - true to disable web3's confirmation listener
    },
    testnet: {
      //provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      provider: function () {
        var wallet = new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`)
        var nonceTracker = new NonceTrackerSubprovider()
        wallet.engine._providers.unshift(nonceTracker)
        nonceTracker.setEngine(wallet.engine)
        return wallet
      },
      network_id: 97,
      confirmations: 0,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 10000000
    },
    bsc: {
      //provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
      provider: function () {
        var wallet = new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`)
        var nonceTracker = new NonceTrackerSubprovider()
        wallet.engine._providers.unshift(nonceTracker)
        nonceTracker.setEngine(wallet.engine)
        return wallet
      },
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 10000000
    },
  },
  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.6",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
          enabled: true,
          runs: 999999 // 999999 
       },
       evmVersion: "byzantium"
      }
    }
  },
  db: {
    enabled: false
  }
};
