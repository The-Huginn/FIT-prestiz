var HelloWorld = artifacts.require("HelloWorld");

module.exports = async function(deployer) {
    deployer.deploy(HelloWorld, "hello");
}