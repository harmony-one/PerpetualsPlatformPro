const { expect } = require("chai");
const { waffle } = require("hardhat");
const { utils } = require("ethers");

use(solidity);

describe("Perpetual Protocol", function () {

  // test data. Use BigNumber to avoid overflow
  const fullAmount = utils.parseEther("1000"); // 1000
  const approvedAmount = utils.parseEther("200"); // 100
  const initialContractBalance = utils.parseEther("50"); // 100

  let usdc;
  let perpetual;


  beforeEach('Set up', async () => {

    [owner, saver, debtor, ...addrs] = await ethers.getSigners();

    const YourContract = await ethers.getContractFactory("YourContract");

    myContract = await YourContract.deploy();



  });

  describe("Can deposit money", function () {
    it("Should allow Owner to start the redeeming phase", async function () {
      // contract call
      await swapcontract.start_redeeming();
      const exchange_rate_end = await swapcontract.exchange_rate_end();

      // should be sucessful
      expect(exchange_rate_end).not.be.null;
      expect(exchange_rate_end).to.equal(await swapcontract.getEUROPrice());
      const principal_balance = await swapcontract.total_pool_prinicipal();
      // expect(principal_balance).to.equal(initialContractBalance.add(approvedAmount));

    });
  });
 
});        
