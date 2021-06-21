var HelloWorld = artifacts.require("HelloWorld");

module.exports = function(deplyer) {
    deployer.deploy(HelloWorld, "hello");
}