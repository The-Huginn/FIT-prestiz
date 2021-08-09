// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

import {DataTypes, Liquidations, Interests} from '../libraries/Utils.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {Reserve} from '../libraries/Reserve.sol';
import {UserConfiguration} from '../libraries/UserConfiguration.sol';
import {Balance} from '../libraries/Balance.sol';

/**
* @author Rastislav Budinsky
* @notice Implementing the ILendingPool interface for the lending pool protocol.
*   The protocol holds information about every user and hold all supported assets
*   the status of deposited balance, interest on this balance as well as the total borrow
*   and the interest accumulated on this borrow.
*/
contract LendingPool is ILendingPool {

    using UserConfiguration for UserConfiguration.UserConfig;
    using Reserve for Reserve.ReserveData;

    // balances and borrows of users
    mapping(address => UserConfiguration.UserConfig) internal users;

    // balance of each token at disposal to protocol
    mapping(address => Reserve.ReserveData) public reserves;

    function deposit(
        address asset,
        uint amount
    ) external override {
        // approve
        require(amount > 0, "Invalid amount to be deposited");

        reserves[asset].depositToReserve(amount);
        users[msg.sender].addDeposit(asset, amount, reserves[asset]);

        emit Deposit(asset, msg.sender, amount);

        // execute transfer
    }

    function withdraw(
        address asset,
        uint amount
    ) external override returns(uint) {

        require(amount > 0, "Invalid amount to be withdrawn");

        // check, if reserve allows the withdrawal, otherwise revert
        reserves[asset].withdrawFromReserve(amount);

        // check, if the user can withdraw, meaning he can has balance and doesnt collaterizes loan, otherwise revert
        users[msg.sender].addWithdraw(asset, amount, reserves[asset], reserves[users[msg.sender].getCollateral(asset, DataTypes.BalanceType.DEFAULT)]);

        emit Withdraw(asset, msg.sender, amount);

        // execute transfer
        return amount;      
    }

    function borrow(
        address collateral,
        address asset,
        uint amount,
        DataTypes.InterestMode interestMode
    ) external override returns(bool) {
        // approve

        require(amount > 0, "Invalid amount to borrow");

        // check, if the user has enough collateral to borrow the wanted amount
        if (Liquidations.checkLiquidated(
                asset,
                users[msg.sender].getTotal(asset, DataTypes.BalanceType.LENDING, reserves[asset]) + amount,
                collateral,
                users[msg.sender].getBalance(collateral, DataTypes.BalanceType.DEFAULT),
                0,
                0,
                0) != DataTypes.LiquidationType.BORROWABLE)
            return false;
        
        // revert-needing actions

        // check, if reserve allows the borrow
        reserves[asset].borrowFromReserve(amount);

        // check, if the user is allowed to take on borrow with his collateral, meaning the previous collateral is either the same or address(0)
        users[msg.sender].addBorrow(asset, amount, collateral, reserves[asset]);

        // change the interest mode of the borrow
        uint interestRate = users[msg.sender].changeInterestMode(asset, DataTypes.BalanceType.LENDING, interestMode, reserves[asset]);

        emit Borrow(collateral, asset, msg.sender, amount, interestMode, interestRate);

        return true;
    }

    // repaying the interest doesn't count towards repaying reserve debt
    function repay(
        address collateral,
        address asset,
        uint amount
    ) external override returns(uint) {

        // approve

        require(amount > 0, "Invalid amount to repay");

        // get actual repaid amount without interest
        uint returnValue = users[msg.sender].addRepay(asset, amount, reserves[asset]);

        // update reserves with the actual amount repaid
        reserves[asset].repayToReserve(returnValue);

        emit Repay(collateral, asset, msg.sender, amount);
        
        return returnValue;
    }

    function liquidationCall(
        address collateral,
        address asset,
        address user
    ) external override {
        users[user].addLiquidation(asset, collateral, reserves[asset], reserves[collateral]);
    }


    // part to be changed hopefully

    function InitializeReserve(
        address token,
        uint total,
        uint fixedBorrowInterest,
        uint fixedDepositInterest,
        uint depositBorrowRate,
        uint healthRate,
        uint decimals
    ) public {
        reserves[token].initializeReserve(
        total,
        fixedBorrowInterest,
        fixedDepositInterest,
        depositBorrowRate,
        healthRate,
        decimals
        );
    }

    function InitializeAvailability(
        address token,
        bool isDeposit,
        bool isBorrow,
        bool isAvailable
    ) public {
        reserves[token].initializeAvailability(
            isDeposit,
            isBorrow,
            isAvailable
        );
    }

    function getUserBalance(address user, address token) external view returns(uint, uint, DataTypes.InterestMode, uint, address)
    {
        return users[user].getInfo(token, reserves[token], DataTypes.BalanceType.DEFAULT);
    }

    function getUserBorrow(address user, address token) external view returns(uint, uint, DataTypes.InterestMode, uint, address)
    {
        return users[user].getInfo(token, reserves[token], DataTypes.BalanceType.LENDING);
    }

    function getReserveBalance(address token) external view returns(uint, uint)
    {
        return (reserves[token].total, reserves[token].borrow);
    }

    function getReserveInterests(address token) external view returns(uint, uint, uint, uint)
    {
        return reserves[token].getInterests();
    }
}