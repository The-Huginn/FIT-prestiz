// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

import {DataTypes} from './Utils.sol';

/**
* @author Rastislav Budinsky
* @notice implements basic struct for user staking and basic functions to operate with the struct
*/
library Staking {

    struct _stake {
        uint total;
        uint interest;
        uint lastEpoch;
    }

    /**
    * @notice Allows you to check the total amount of FITCOIN staked
    * @param stake Stake of specific user
    * @return the amount of FITCOIN staked with rewards
    */
    function getStakeTotal(_stake storage stake) public view returns(uint)
    {
        return stake.total + getAccruedInterest(stake);
    }

    /**
    * @notice shows how much interest has the user accrued so far
    * @param stake Stake of specific user
    * @return the amount of accrued interest
    */
    function getAccruedInterest(_stake storage stake) public view returns(uint)
    {
        return stake.interest;
    }

    /**
    * @notice shows the epoch of the last change
    * @param stake Stake of specific user
    * @return returns the latest epoch
    */
    function getLastEpoch(_stake storage stake) internal view returns(uint)
    {
        return stake.lastEpoch;
    }

    /**
    * @notice stake FITCOIN and adds transaction to the user's log
    * @param stake Stake of specific user
    * @param amount the amount of FICOINs to be staked
    * @param epoch the epoch at which the staking starts
    * @param token the address of FITCOIN
    */
    function addStake(
        _stake storage stake,
        uint amount,
        uint epoch,
        address token
    ) internal {
        addTransaction(stake, token, amount, DataTypes.TransactionType.STAKE);
        changeLastEpoch(stake, epoch);
    }

    /**
    * @notice unstake FITCOIn and adds transaction to the user's log, might fail if not enough balance
    * @param stake Stake of specific user
    * @param amount the amount of FITCOINs to be unstaked
    * @param epoch the epoch at which the unstaking happens
    * @param token the address of FITCOIN
    */
    function addUnstake(
        _stake storage stake,
        uint amount,
        uint epoch,
        address token
    ) internal {

        require(getStakeTotal(stake) >= amount, "Trying to unstake more than enough");
        
        addTransaction(stake, token, amount, DataTypes.TransactionType.UNSTAKE);
        changeLastEpoch(stake, epoch);
    }

    /**
    * @notice allows to send interest (FITCOIN, lendingpool, dex) to the user
    * @param stake Stake of specific user
    * @param amount the amount of FITCOINs added as interest
    * @param token the address of token reward
    * @param minting true if the reward is minting new token to the user, false if it's every other reward e.g. lending pool reward
    */
    function addStakeInterest(
        _stake storage stake,
        address token,
        uint amount,
        bool minting
    ) internal {
        addTransaction(stake, token, amount, minting ? DataTypes.TransactionType.STAKE_REWARD_FITCOIN: DataTypes.TransactionType.STAKE_REWARD_OTHER);
    }

    /**
    * @notice allows user to redeem his accrued staking interest of FITCOIN
    * @param stake Stake of specific user
    * @param token the address of FITCOIN
    */
    function addRedeem(
        _stake storage stake,
        address token
    ) internal {
        addTransaction(stake, token, getAccruedInterest(stake), DataTypes.TransactionType.STAKE_REDEEM);
    }

    /**
    * @notice allows the protocol to slash user's staked amount
    * @param stake Stake of specific user
    * @param amount the amount to be slashed
    * @param token the address of FITCOIN
    */
    function addSlash(
        _stake storage stake,
        uint amount,
        address token
    ) internal {
        addTransaction(stake, token, amount, DataTypes.TransactionType.SLASH);
    }

    /**
    * @notice changes the last epoch, should be called for upon stake and unstake
    * @param stake Stake of specific user
    * @param epoch the epoch timestamp
    */
    function changeLastEpoch(
        _stake storage stake,
        uint epoch
    ) internal {
        // to prevent stake & unstake abusement in the same epoch
        stake.lastEpoch = epoch > stake.lastEpoch ? epoch : stake.lastEpoch;
    }

    /**
    * @dev adds transaction to the log, only stake and unstake updates the timestamp, unstaking takes first interest
    *       slashing takes first the interest
    * @param stake instance of stake
    * @param token the address of the token
    * @param amount the amount in the transaction
    * @param typ the type of transaction
    */
    function addTransaction(
        _stake storage stake,
        address token,
        uint amount,
        DataTypes.TransactionType typ
    ) private {
        if (typ == DataTypes.TransactionType.UNSTAKE || typ == DataTypes.TransactionType.SLASH)
            require(getStakeTotal(stake) >= amount, "Insufficient amount staked, trying to unstake/slash too much");

        // only want to log transaction
        if (typ == DataTypes.TransactionType.STAKE_REWARD_OTHER)
            return;

        if (typ == DataTypes.TransactionType.STAKE || typ == DataTypes.TransactionType.UNSTAKE)
        {
            if (typ == DataTypes.TransactionType.STAKE)
                stake.total += amount;
            else
            {
                stake.total -= amount;
            }
        }
        else if (typ == DataTypes.TransactionType.STAKE_REWARD_FITCOIN)
        {
            stake.interest += amount;
        }
        else if (typ == DataTypes.TransactionType.SLASH)
        {
            stake.total -= amount;
        }
        else if (typ == DataTypes.TransactionType.STAKE_REDEEM)
        {
            stake.interest = 0;
        }
        else
           revert("Invalid transaction parameter");
    }
}