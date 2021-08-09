// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

interface IStakingPool {
    
    /**
    * @dev Emitted on stake
    * @param user the user staking
    * @param amount the amount of FITCOIN being added to stake
    * @param epoch the epoch at which the stake was added
    */
    event Stake(
        address user,
        uint amount,
        uint indexed epoch
    );

    /**
    * @dev Emitted on unstake
    * @param user the user unstaking
    * @param amount the amount of FITCOIN being unstaked
    * @param epoch the epoch at which was the unstake
    */
    event Unstake(
        address user,
        uint amount,
        uint indexed epoch
    );

    /**
    * @dev Emitted on redeeming the staking interest
    * @param user the user redeeming the staking interest
    * @param amount the interest being redeemed
    */
    event Redeem(
        address user,
        uint amount
    );

    /**
    * @dev Adding FITCOIN to the staking pool
    * @param amount the amount of FITCOIN begin added to the staking pool
    */
    function stake(
        uint amount
    ) external;

    /**
    * @dev Removing FITCOIN from the staking pool
    * @param amount the amount of FITCOIN being removed from the staking pool
    */
    function unstake(
        uint amount
    ) external;

    /**
    * @dev Redeeming the staking interest
    */
    function redeem(
    ) external;
}