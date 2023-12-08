const Collector = artifacts.require("Collector");

module.exports = async(deployer, network, accounts) => {
    await deployer.deploy(Collector, "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419");
    const collector = await Collector.deployed();
    console.log("Deployed wallet is @: " + collector.address);
}