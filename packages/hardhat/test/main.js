const { expect } = require("chai");
const { waffle } = require("hardhat");
const { utils } = require("ethers");


describe("Perpetual Protocol", function () {

  // test data. Use BigNumber to avoid overflow
  const supply = utils.parseEther("100000000000000000000"); 
  const vUSDreserve = utils.parseEther("100000"); 
  const vXAUreserve = utils.parseEther("55"); 
  const investAmount = utils.parseEther("100")
  const leverage = 5;

  let usdc;
  let perpetual;
  let ownerAmount;

  beforeEach('Set up', async () => {

    [owner, user1, user2, ...addrs] = await ethers.getSigners();

    const USDC = await ethers.getContractFactory("USDC");
    usdc = await USDC.connect(owner).deploy(supply);

    const Perpetual = await ethers.getContractFactory("Perpetual");
    perpetual = await Perpetual.connect(owner).deploy(usdc.address, vUSDreserve, vXAUreserve, leverage );

  });

  describe("Can be deployed", function () {
    it("Should given tokens with deployment ", async function () {
      ownerAmount = await usdc.balanceOf(owner.address);
      expect(ownerAmount).to.be.equal(supply);
    });
    it("Should given public variables ", async function () {
      const USDC = await perpetual.USDC();
      expect(USDC).to.be.equal(usdc.address);
    });
    it("Should give owner to deployer address ", async function () {
      const contractOwner = await perpetual.owner();
      expect(contractOwner).to.be.equal(owner.address);
    });
  });

  describe("Can deposit/withdraw USDC", function () {
    it("Should give allowance to perpetual", async function () {
      await usdc.connect(owner).approve(perpetual.address, investAmount);
      const allowance = await usdc.allowance(owner.address, perpetual.address);
      expect(allowance).to.be.equal(investAmount);

    });
    it("Should deposit USDC", async function () {
      await usdc.connect(owner).approve(perpetual.address, investAmount);
      const allowance = await usdc.allowance(owner.address, perpetual.address);
      expect(allowance).to.be.equal(investAmount);

      await expect(perpetual.deposit(investAmount))
        .to.emit(perpetual, 'Deposit')
        .withArgs(investAmount, owner.address);

    });
    it("Should withdraw USDC", async function () {
      await usdc.connect(owner).approve(perpetual.address, investAmount);
      await perpetual.deposit(investAmount)

      await expect(perpetual.withdraw(investAmount))
      .to.emit(perpetual, 'Withdraw')
      .withArgs(investAmount, owner.address);
    
    });
  });

  describe("Can trade vXAU", function () {
    it("Should buy vXAU", async function () {
      await usdc.connect(owner).approve(perpetual.address, investAmount);
      await perpetual.deposit(investAmount);

      await expect(perpetual.MintLongXAU(investAmount))
      .to.emit(perpetual, 'LongXAUminted')
      .withArgs(utils.parseEther("0.273631840796019901"), owner.address);

    });
    it("Should sell vXAU", async function () {
      await usdc.connect(owner).approve(perpetual.address, investAmount);
      await perpetual.deposit(investAmount);

      await perpetual.MintLongXAU(investAmount);
      const XAUamount = await perpetual.vXAUlong(owner.address);


      await expect(perpetual.RedeemLongXAU(XAUamount))
      .to.emit(perpetual, 'LongXAUredeemed')
      .withArgs(utils.parseEther("500"), owner.address);

    });
    it("Should sell vXAU", async function () {
      price = await perpetual.getPrice();
      expect(price).to.be.to.be.at.least(0)
      //console.log("Current price is", utils.formatEther(price));
    });
  });

  describe("Can trade calculate funding payments", function () {
    it("Should calculate funding rate", async function () {
      await perpetual.updateFundingRate();
      const funding = await perpetual.funding();
      
      expect(funding.rate).to.be.equal(utils.parseUnits("0.00179425", 8));
      expect(funding.isPositive).to.be.true;

    });
    it("Should apply the funding rate to long balances", async function () {
      // invest money into balance
      await usdc.connect(owner).approve(perpetual.address, investAmount);
      await perpetual.deposit(investAmount);
      await perpetual.MintLongXAU(investAmount);
      
      // update funding rate
      await perpetual.updateFundingRate();

      // apply funding rate
      await perpetual.applyFundingRate();

      const amountAfter = await perpetual.vXAUlong(owner.address);
      await expect(amountAfter)
      .to.be.equal(utils.parseEther("0.274013428606965174"));
    });
  });
});        
