const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Raffle", function () {
  async function deployOneMonthDurationFixture() {
    const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    const startTime = await time.latest();
    const endTime = startTime + ONE_MONTH_IN_SECS;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const ProjectToken = await ethers.getContractFactory("MyToken");
    const projectToken = await ProjectToken.deploy();
    const tokenAddress = await projectToken.getAddress();

    const Raffle = await ethers.getContractFactory("Raffle");
    const raffle = await Raffle.deploy(
      tokenAddress,
      10,
      startTime,
      endTime,
      owner
    );

    return { raffle, projectToken, owner, otherAccount, endTime };
  }

  describe("Deployment", function () {
    it("Custom token should be deployed correctly!", async function () {
      const { projectToken, owner, otherAccount } = await loadFixture(
        deployOneMonthDurationFixture
      );

      await projectToken.transfer(
        otherAccount.address,
        "500000000000000000000000"
      );
      expect(await projectToken.balanceOf(owner.address)).to.equal(
        "500000000000000000000000"
      );
    });

    it("User should buy more than 0 tickets!", async function () {
      const { raffle } = await loadFixture(deployOneMonthDurationFixture);

      await expect(raffle.buyTickets(0)).to.be.revertedWith(
        "Raffle: Number of tickets must be greater than 0"
      );
    });

    it("User shoule have enough token to buy tickets!", async function () {
      const { raffle, otherAccount } = await loadFixture(
        deployOneMonthDurationFixture
      );

      await expect(
        raffle.connect(otherAccount).buyTickets(10)
      ).to.be.revertedWith("Raffle: Insufficient balance");
    });

    it("User should approve before buy tokens!", async function () {
      const { raffle } = await loadFixture(deployOneMonthDurationFixture);

      await expect(raffle.buyTickets(10)).to.be.revertedWith(
        "Raffle: Token not approved"
      );
    });

    it("Buying function should work!", async function () {
      const { raffle, projectToken } = await loadFixture(
        deployOneMonthDurationFixture
      );

      const raffleAddress = await raffle.getAddress();
      await projectToken.approve(raffleAddress, "500000000000000000000000");
      await raffle.buyTickets(10);
      const participants = await raffle.getParticipants();
      expect(participants.length).to.equal(10);
    });

    it("Several users can buy!", async function () {
      const { raffle, projectToken, otherAccount } = await loadFixture(
        deployOneMonthDurationFixture
      );

      await projectToken.transfer(
        otherAccount.address,
        "500000000000000000000000"
      );

      const raffleAddress = await raffle.getAddress();

      await projectToken.approve(raffleAddress, "500000000000000000000000");
      await projectToken
        .connect(otherAccount)
        .approve(raffleAddress, "500000000000000000000000");

      await raffle.buyTickets(10);
      await raffle.connect(otherAccount).buyTickets(20);
      await raffle.connect(otherAccount).buyTickets(15);
      await raffle.buyTickets(5);

      const participants = await raffle.getParticipants();
      expect(participants.length).to.equal(50);
    });

    it("Only owner can draw raffle!", async function () {
      const { raffle, endTime } = await loadFixture(
        deployOneMonthDurationFixture
      );

      await time.increaseTo(endTime);
      await expect(raffle.drawRaffle()).to.be.revertedWith(
        "Raffle: No participants"
      );
    });

    it("Select random participant!", async function () {
      const { raffle, projectToken, otherAccount, endTime } = await loadFixture(
        deployOneMonthDurationFixture
      );

      await projectToken.transfer(
        otherAccount.address,
        "500000000000000000000000"
      );

      const raffleAddress = await raffle.getAddress();

      await projectToken.approve(raffleAddress, "500000000000000000000000");
      await projectToken
        .connect(otherAccount)
        .approve(raffleAddress, "500000000000000000000000");

      await raffle.buyTickets(10);
      await raffle.connect(otherAccount).buyTickets(20);
      await raffle.connect(otherAccount).buyTickets(15);
      await raffle.buyTickets(5);

      await time.increaseTo(endTime);

      await expect(raffle.drawRaffle())
          .to.emit(raffle, "RaffleDrawn")
          .withArgs(anyValue, anyValue);
    });
  });
});
