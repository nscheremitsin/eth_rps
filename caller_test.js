const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("All tests", () => {
    let rps;
    let caller;
    let rpsAddress;

    beforeEach(async () => {
        // В ремиксе следующая строка выдает ошибку артифакта, для устранения
        // которой название контракта нужно поменять на RPS 1) в .sol, 2) здесь
        let RPS = await ethers.getContractFactory("RockPaperScissors");
        rps = await RPS.deploy();
        rpsAddress = rps.address;
        let Caller = await ethers.getContractFactory("Caller");
        caller = await Caller.deploy();
    });

    it("Single start IS NOT reverted", async () => {
        await expect(caller.start(rpsAddress)).to.not.be.reverted;
    });
    it("Single cancel after signle start IS NOT reverted", async () => {
        await caller.start(rpsAddress);
        await expect(caller.cancel(rpsAddress)).to.not.be.reverted;
    });
    it("Cancel before start IS reverted", async () => {
        await expect(caller.cancel(rpsAddress)).to.be.reverted;
    });
    it("Second start after previous start IS reverted", async () => {
        await expect(caller.start(rpsAddress)).to.not.be.reverted;
        await expect(caller.start(rpsAddress)).to.be.reverted;
    });
});