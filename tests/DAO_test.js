import { time, loadFixture,  } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, network, } from "hardhat";

describe("DAO Tests", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploy() {
    const [deployer, account1, account2, account3] = await ethers.getSigners();

    const Trader = await ethers.getContractFactory("Trader");
    const trader = await Trader.deploy();

    const proposals = ['buy_bitcoins', 'not_buy_bitcoins']
    const SimpleDAO = await ethers.getContractFactory("simpleDAO");
    const dao = await SimpleDAO.deploy(trader.address, 86400, proposals);

    return { dao, trader, deployer, account1, account2, account3 };
  }

  describe("Deployment", function () {

    it("Should check trader address", async function () {
      const { dao, trader } = await deploy();

      let traderAddr = await dao.traderAddress();

      expect(traderAddr).to.equal(trader.address);
    });


    it("Should revert on double vote", async function () {
      const Trader = await ethers.getContractFactory("Trader");
      const trader = await Trader.deploy();
      const proposals = ['buy_bitcoins', 'not_buy_bitcoins']
      const SimpleDAO = await ethers.getContractFactory("simpleDAO");
      const dao = await SimpleDAO.deploy(trader.address, 86400, proposals);
      const [account1] = await ethers.getSigners();

      const yes = 0;

      await dao.connect(account1).vote(yes);
      await expect(dao.connect(account1).vote(yes)).to.be.reverted; // acutally the transaction will fail
    });


    it("Should vote", async function () {
        const { dao, account1, account2, account3 } = await loadFixture(deploy);

        const yes = 0;
        const no = 1;

        let amountPayable = {value: ethers.utils.parseEther("0.05")};

        await dao.connect(account1).DepositEth(amountPayable);
        await dao.connect(account2).DepositEth(amountPayable);

        await dao.connect(account1).vote(yes);
        await dao.connect(account2).vote(yes);
        await dao.connect(account3).vote(no);

  
        // change time
        await ethers.provider.send("evm_increaseTime", [(24 * 60 * 60) + 60]);
        await network.provider.send("evm_mine");


        await dao.countVote();
        let decision = await dao.decision();

        expect(decision).to.equal(0);

        await dao.EndVote(); // dao is not a signer, cannot purchase in the test

        console.log("BTC position: ", dao.BTCposition());
        console.log("BTC price: ", dao.BTCprice());
        console.log("ETH price: ", dao.ETHprice());
    });
  });
});