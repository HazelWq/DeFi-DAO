// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

beforeEach(async () => {
    const [owner,address1,address2,address3] = await ethers.getSigners(); 
    
    const Trader = await ethers.getContractFactory("Trader");
    const trader = await Trader.deploy();
  });


describe("Trader Contract Unit Tests", function () {
  
  describe("Deployment", function () {

    it("Should get owner", async function () {
      let owner = await trader.owner();
      expect(owner).to.equal(owner);
    });

    it("Should show ETH reserve", async function () {
      let balance = await trader.ETHreserve(trader.address);
      expect(balance).to.equal(0);
    });
  
    it("Should be able to refill", async function () {
      let amount = 5;
      await trader.connect(owner).refill(amount);
      let balance = await trader.ETHreserve(owner.address);
      expect(balance).to.equal(amount);
    });
  
    it("Should be able to purchase", async function () {

      await trader.connect(owner).purchase({value: ethers.utils.parseEther("0.01")}); //options
      let balance = await trader.ETHreserve(owner.address);
      expect(balance).to.equal(ethers.utils.parseEther("0.01"));
    });
  });
});