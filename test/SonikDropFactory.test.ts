import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre from "hardhat";
  
  describe("SonikDrop Factory", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployTestToken() {
      // Contracts are deployed using the first signer/account by default
      const [owner, account1] = await hre.ethers.getSigners();
      const GojouToken = await hre.ethers.getContractFactory("GojouToken");
      const gojouToken = await GojouToken.connect(account1).deploy();
  
      return { gojouToken};
    }
  
    async function deploySonikDropFactory() {
      const [owner, account1,account2, account3, account4, account5] = await hre.ethers.getSigners();
      const { gojouToken } = await loadFixture(deployTestToken);

      const SonikDropFactory = await hre.ethers.getContractFactory("SonikDropFactory");
      const sonikDropFactory = await SonikDropFactory.deploy();

      return { sonikDropFactory, owner, account1, account2, account3, gojouToken, account4, account5 };
    }
  
    describe("Deployment", function () {
      it("Should set the parameters properly on deployment", async function () {
        const { sonikDropFactory, owner, gojouToken, account1 } = await deploySonikDropFactory();
  
        expect(await sonikDropFactory.collector()).to.equal(owner);
        expect(await sonikDropFactory.baseFee()).to.equal(0);
        expect(await sonikDropFactory.cloneCount()).to.equal(0);
        expect( await gojouToken.owner()).to.equal(account1);
      });
  
    });
  
  });
  