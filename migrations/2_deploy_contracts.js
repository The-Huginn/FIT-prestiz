const { ETHER_ADDRESS } = require("../test/helpers/helpers");

// contracts
const PriceAggregator = artifacts.require("PriceAggregator");
const LendingPool = artifacts.require("LendingPool");
const StakingPool = artifacts.require("StakingPool");
const Token = artifacts.require("Token");

// libraries
    // Utils
    const DataTypes = artifacts.require("DataTypes");
    const Liquidations = artifacts.require("Liquidations");
    const Interests = artifacts.require("Interests");

    // UserConfiguration
    const UserConfiguration = artifacts.require("UserConfiguration");

    // Balance
    const Balance = artifacts.require("Balance");

    // Reserve
    const Reserve = artifacts.require("Reserve");

    // Staking
    const Staking = artifacts.require("Staking");

    // StakingReserveLib
    const StakingReserveLib = artifacts.require("StakingReserveLib");

async function doDeploy(deployer, network, accounts)
{    
    await deployer.deploy(DataTypes);
    await deployer.link(DataTypes, [Liquidations, Interests, Balance, Staking,  UserConfiguration, LendingPool]);

    await deployer.deploy(Liquidations);
    await deployer.deploy(Interests);

    await deployer.link(Liquidations, [UserConfiguration, LendingPool]);
    await deployer.link(Interests, [LendingPool, UserConfiguration]);

    await deployer.deploy(Staking);
    await deployer.deploy(Balance);
    await deployer.link(Balance, UserConfiguration);
    await deployer.deploy(Reserve);
    await deployer.deploy(StakingReserveLib);
    await deployer.deploy(UserConfiguration);

    await deployer.link(UserConfiguration, LendingPool);
    await deployer.link(Reserve, LendingPool);

    await deployer.link(Staking, StakingPool);
    await deployer.link(StakingReserveLib, StakingPool);


    await deployer.deploy(PriceAggregator);    
    const priceAggregator = await PriceAggregator.deployed();

    await deployer.deploy(LendingPool);
    const lendingPool = await LendingPool.deployed();

    await deployer.deploy(StakingPool);
    const stakingPool = await StakingPool.deployed();

    await deployer.deploy(Token, accounts[0], accounts[1], stakingPool.address);
    const token = await Token.deployed();

    // set second argument as invoker address to wake contract up
    await stakingPool.initialize(
        token.address,
        lendingPool.address
    );
}

module.exports = async function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
}