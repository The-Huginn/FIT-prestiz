pragma solidity ^0.7.5;

import {Interest} from './Utils.sol';

interface ILendingPool {

    /**
    * @dev Emitted on deposit
    * @param asset The address of the deposited asset
    * @param user The address the deposit was initiated by
    * @param amount The amount deposited
    */
    event Deposit(
        address indexed asset,
        address user,
        uint amount
    );

    /**
    * @dev Emitted on withdraw
    * @param asset The address of the deposited asset
    * @param user The address withdrawing collateral
    * @param amount The amount to be withdrawn
    */
    event Withdraw(
        address indexed asset,
        address user,
        uint amount
    );

    /**
    * @dev Emitted on borrow
    * @param collateral The address of the underlying asset
    * @param asset The address of the second asset to identify the pool pair
    * @param user The address borrowing the asset
    * @param amount The amount to be borrowed by user
    * @param interestMode The mode of interest
    * @param interestRate The numeric rate at which the user borrow the asset
    */
    event Borrow(
        address indexed collateral,
        address indexed asset,
        address user,
        uint amount,
        Interest.InterestMode interestMode,
        uint interestRate
    );

    /**
    * @dev Emitted on repay
    * @param collateral The address of the underlying asset
    * @param asset The address of the second asset to identify the pool pair
    * @param user The address repaying it's debt
    * @param amount The amount repaid
    */
    event Repay(
        address indexed collateral,
        address indexed asset,
        address user,
        uint amount
    );

    /**
    * @dev Emmited on liquidation of underlying asset
    * @param collateral The address of the underlying asset
    * @param asset The address of the second asset to identify the pool pair
    * @param user The address in debt
    * @param liquidator The address requesting it's funds
    * @param amount The debt amount
    */
    event LiquidationCall(
        address indexed collateral,
        address indexed asset,
        address user,
        address liquidator,
        uint amount
    );

    /**
    * @dev Deposits the amount of underlying asset
    * @param asset The address of the deposited asset
    * @param amount The amount to be deposited
    */
    function deposit(
        address asset,
        uint amount
    ) external;

    /**
    * @dev Withdraws the amount of underlying asset
    * @param asset The address of the deposited asset
    * @param amount The amount to be withdrawn
    * @return The final amount to be withdrawn
    */
    function withdraw(
        address collateral,
        address asset,
        uint amount
    ) external returns(uint);

    /**
    * @dev The user can is allowed to borrow the asset
    * @param collateral The address of underlying asset
    * @param asset The address of the second asset to identify the pool pair
    * @param amount The amount user wants to borrow
    * @param interestMode The mode of interest
    * @return true on success
    */
    function borrow(
        address collateral,
        address asset,
        uint amount,
        Interest.InterestMode interestMode
    ) external returns(bool);

    /**
    * @dev The user repays his debt
    * @param collateral The address of the underlying asset
    * @param asset The address of the second asset to identify the pool pair
    * @param amount The amount user wants to repay
    * @return The final amount repaid
    */
    function repay(
        address collateral,
        address asset,
        address amount
    ) external returns(uint);

    /**
    * @dev Liquidating non-collateralized borrow if the borrowed amount + interest is over the treshold
    *   which should cover the market risk as well
    * @param collateral The address of the underlying asset
    * @param asset The address of the second asset to identify the pool pair
    * @param user The address getting liquidated
    */
    function liquidationCall(
        address collateral,
        address asset,
        address user
    ) external;


}