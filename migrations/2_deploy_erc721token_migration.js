var ERC721Token = artifacts.require("ERC721Token");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(ERC721Token,'test', 'test');
};