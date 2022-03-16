const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require('truffle-assertions');

contract("Dex", accounts => {
    it("should only be possible for owners to add tokens", async () => { //this is to test the addToken function
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await truffleAssert.passes(
            dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]}) //"passes" means to test whether the addToken done from accounts[0] is approved
        )
        await truffleAssert.reverts(
            dex.addToken(web3.utils.fromUtf8("AAVE"), link.address, {from: accounts[1]}) //"reverts" means to test whether the addToken done from accounts[1] is correctly blocked
        )
    })
    it("should handle deposits correctly", async () => { //this is to test the deposit in the SC
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await link.approve(dex.address, 500);
        await dex.deposit(499, web3.utils.fromUtf8("LINK"));
        let balance = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"));
        assert.equal(balance.toNumber(), 499);
    })
    it("should handle faulty withdrawals correctly", async () => { //this is to test faulty withdrawals (such as bigger amount than what's available) in the SC
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await truffleAssert.reverts(dex.withdraw(501, web3.utils.fromUtf8("LINK")));
    })
    it("should handle correct withdrawals correctly", async () => { //this is to test correct/allowed withdrawals in the SC
        let dex = await Dex.deployed();
        let link = await Link.deployed();
        await truffleAssert.passes(dex.withdraw(499, web3.utils.fromUtf8("LINK")));
    })
})