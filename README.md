# Perpetuals Platform Pro 

Hackathon project of the [Web3 Weekend](https://web3.ethglobal.co/)
* https://showcase.ethglobal.co/web3weekend/perpetuals-platform-pro


---
The Perpetuals Platform Pro is an on-chain AMM-based futures platform that allows you to trade commodities and forex, utilizing chainlink price oracles and IPFS for storage.
Inspired by the Perpetual Protocol, we also use a peer-to-pool system design. There are 5 main components of the protocol:
1) Vault: When a trader opens a position on the platform, the collateral is locked in the Vault. When a trader closes a position, the PnL will be unlocked from the Vault.
2) Clearing Configurator: The Clearing Configurator provides high-level information (directional (long or short), margin, etc) to the vAMM for price discovery.
3) vAMM: The vAMM is based on the constant product formula (x*y=k) and mints or burns virtual tokens in the x and y pools which will reflect a change in the price. 
4) Funding Rate: A funding rate is required to converge the Last Price to the Chainlink oracle price.
5) Liquidations: Third-party keeper bots will liquidate positions once the position value drops below the margin ratio.
Please see if this will be good enough for the README and description in our submission

## forked from [🏗 scaffold-eth](https://github.com/austintgriffith/scaffold-eth)
##> Everything you need to get started building decentralized applications on Ethereum! 🚀 
