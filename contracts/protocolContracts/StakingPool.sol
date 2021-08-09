// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

import {StakingReserveLib} from '../libraries/StakingReserveLib.sol';
import {IStakingPool} from '../interfaces/IStakingPool.sol';
import {Staking} from '../libraries/Staking.sol';
import {DataTypes} from '../libraries/Utils.sol';
import '../open-zeppelin/ERC20.sol';

contract StakingPool is IStakingPool {
    
    using Staking for Staking._stake;
    using StakingReserveLib for StakingReserveLib.StakingReserve;

    uint private endMinting;        // timestamp of expected 8 years minting
    uint private rewardPerSecond;   // reward of fitcoin per second passed (distribution is linear)
    uint private lastTimestamp;     // timestamp of the last stake/unstake from the protocol

    // balances of users
    mapping(address => Staking._stake) public users;

    // balance of the staking pool
    StakingReserveLib.StakingReserve public stakingReserve;

    // address of fitcoin
    address public fitcoin_address;
    // interface of FITCOIN
    ERC20 public fitcoin;
    // address of lending pool for slashing
    address public lendingPoolAddress;
    // to prevent from being deployed multiple times
    bool private deployed = false;



    // end rewards after 8 years of "minting" new tokens
    constructor () public {
        endMinting = block.timestamp + 8 * DataTypes.secondsPerYear;
    }

    modifier onlyLendingPool ()
    {
        require(msg.sender == lendingPoolAddress, "Only Lending pool is allowed to access this function");
        _;
    }

    // no need for onlyOwner as it should be changed right on deployement
    function initialize(ERC20 _token, address _lendingPoolAddress) public
    {
        require(deployed == false, "fitcoin address already changed");
        
        lendingPoolAddress = _lendingPoolAddress;

        fitcoin_address = address(_token);
        fitcoin = _token;
        stakingReserve.initializeStakingReserve(fitcoin.decimals());
        // fitcoin_address = _fitcoin;

        rewardPerSecond = fitcoin.balanceOf(address(this)) / (8 * DataTypes.secondsPerYear);


        deployed = true;
    }

    function stake(
        uint amount
    ) external override {

        (uint interest, uint epoch) = stakingReserve.stakeToReserve(users[msg.sender].getStakeTotal(), amount, users[msg.sender].getLastEpoch());

        users[msg.sender].addStakeInterest(fitcoin_address, interest, true);

        users[msg.sender].addStake(amount, epoch, fitcoin_address);

        payInterest();

        emit Stake(msg.sender, amount, epoch);
    }

    function unstake(
        uint amount
    ) external override {

        (uint interest, uint epoch) = stakingReserve.unstakeFromReserve(users[msg.sender].getStakeTotal(), amount, users[msg.sender].getLastEpoch());

        users[msg.sender].addStakeInterest(fitcoin_address, interest, true);

        users[msg.sender].addUnstake(amount, epoch, fitcoin_address);

        payInterest();
        
        emit Unstake(msg.sender, amount, epoch);
    }

    function redeem() external override 
    {
        // redeeming shouldn't affect the epoch
        (uint interest,) = stakingReserve.calculateInterest(users[msg.sender].getStakeTotal(), users[msg.sender].getLastEpoch());
        
        interest += users[msg.sender].getAccruedInterest();

        users[msg.sender].addRedeem(fitcoin_address);
        
        // get the actual amount redeemed
        emit Redeem(msg.sender, interest);
    }

    /**
    * @dev function should be called after every change in stakingPool
    *   regarding staking and unstaking to add rewards and calculate proper amounts
    */
    function payInterest() public
    {
        // no more minting rewards allowed after 8 years
        if (block.timestamp > endMinting)
            return;
        
        uint time = lastTimestamp == 0 ? 0 : block.timestamp - lastTimestamp;
        uint reward = time * rewardPerSecond;

        lastTimestamp = block.timestamp;
        // pay users interest and move onto the next epoch
        stakingReserve.rewardToReserve(reward);
    }

    /**
    * @dev function accessible only by the lending pool in order to slash stakers and restore
    * rewards at lending pool, expecting total balance needed in ETH
    */
    function slash(uint balanceNeeded) onlyLendingPool public returns(bool)
    {
        // time of 2 weeks
        // if (lastSlash + 60*60*24*14 < block.timestamp)
        //     return false;

        // get price of FITCOIN in eth
        uint pricePerFitcoin;
        uint totalAvailable = (30 * stakingReserve.getTotal()) / 100;       // only 30% slashed max

        if (pricePerFitcoin * totalAvailable > balanceNeeded)
            return false;
            
        return true;
    }
}