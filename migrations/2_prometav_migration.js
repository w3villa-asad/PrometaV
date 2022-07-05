const Prometav = artifacts.require("Prometav");

module.exports = function(deployer) {
    const adminAddress = '0x15FF7F505Ea527f90a93321cA2c3018Cd95d7c57';
    deployer.deploy(Prometav, adminAddress);
};