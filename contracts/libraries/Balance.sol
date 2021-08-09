// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

import {DataTypes, Interests} from './Utils.sol';
import {Reserve} from './Reserve.sol';


/**
* @author Rastislav Budinsky
* @dev library for struct of ledger holding record of transaction details,
*   total balance, interest mode and accrued interest and timestamp of the
*   last change to the ledger
*   ! Be aware, initialize should be always called as first to set up variables for full functioning
*/
library Balance {
    
    using Reserve for Reserve.ReserveData;

    struct _balance{
        
        // the total balance of the user
        uint total;
        
        // interest and account types
        DataTypes.InterestMode interestMode;
        DataTypes.BalanceType accountType;

        uint timestamp;

        // accrued interest
        uint accruedInterest;

        // interest rate, important for fixed rate
        uint interestRate;

        // address of the token
        address asset;

        // address of the collateral for borrowing
        // and address of the borrowing for collateral
        address collateral;
    }

    /**
    * @dev Initializes _balance struct to parameter values and interest mode sets to variable
    * @param balance the _balance struct to be initialized
    * @param balanceT the type of balance this is ( DEFAULT / LENDING )
    * @param _asset the address of the asset
    */
    function _initialize(
        _balance storage balance,
        DataTypes.BalanceType balanceT,
        address _asset
    ) internal {
        balance.accountType = balanceT;
        balance.asset = _asset;
        balance.interestMode = DataTypes.InterestMode.VARIABLE;
        _updateTimestamp(balance);
    }

    function _getInfo(
        _balance storage balance,
        Reserve.ReserveData storage reserve
    ) internal view returns(uint, uint, DataTypes.InterestMode, uint, address) {
        return (balance.total, _getAccruedInterest(balance, reserve), balance.interestMode, balance.interestRate, balance.collateral);
    }

    function _getBalance(_balance storage balance) internal view returns(uint)
    {
        return balance.total;
    }

    function _getTotal(
        _balance storage balance,
        Reserve.ReserveData storage reserve
    ) internal view returns(uint) {
        return _getBalance(balance) + _getAccruedInterest(balance, reserve);
    }

    function _getLastTimestamp(_balance storage balance) internal view returns(uint)
    {
        return balance.timestamp;
    }

    function _getAccruedInterest(
        _balance storage balance,
        Reserve.ReserveData storage reserve
    ) internal view returns(uint) {
        return /*balance.accruedInterest +*/ _calculateInterest(balance, reserve);
    }

    function _getInterestMode(_balance storage balance) internal view returns(DataTypes.InterestMode)
    {
        return balance.interestMode;
    }

    function _getInterestRate(_balance storage balance) internal view returns(uint)
    {
        return balance.interestRate;
    }

    function _getCollateral(_balance storage balance) internal view returns(address)
    {
        return balance.collateral;
    }

    /**
    * @dev add transaction to the ledger info, updates total amount, timestamp of getting executed
    *   and accrued DataTypes. Transaction types so far
    *   DEPOSIT
    *   WITHDRAW
    *   BORROW
    *   REPAY
    * @param balance the _balance struct to which adding the transaction
    * @param _token the address of the token
    * @param _amount the amount in the transaction
    * @param _type the type of transaction, see above
    * @param _collateral in case its collaterized transaction
    * @param _reserve the reserve pool of the asset
    * @return returns 0 by default, in repay transaction returns the actual amount repaid without interest
    */
    function _addTransaction(
        _balance storage balance,
        address _token,
        uint _amount,
        DataTypes.TransactionType _type,
        address _collateral,
        Reserve.ReserveData storage _reserve
    ) internal returns(uint) {
        // return value, change in repay transaction
        uint returnValue = 0;

        if (_type == DataTypes.TransactionType.WITHDRAW)
            require(_amount <= _getTotal(balance, _reserve), "Can't withdraw due to low total");

        // update accrued interest
        _updateInterest(balance, _reserve);

        // update total balance, interest goes first
        if (_type == DataTypes.TransactionType.DEPOSIT)
        {
            balance.total += _amount;
        }
        else if (_type == DataTypes.TransactionType.BORROW)
            {
                // collateral is initiated
                if (balance.collateral != address(0))
                    require(balance.collateral == _collateral, "You can collaterize your borrow only with the same collateral");
                
                balance.collateral = _collateral;

                balance.total += _amount;
            }
        else if (_type == DataTypes.TransactionType.WITHDRAW)
        {
            if (balance.accruedInterest >= _amount)
                balance.accruedInterest -= _amount;
            else
            {
                _amount -= balance.accruedInterest;
                balance.accruedInterest = 0;
                balance.total -= _amount > balance.total ? balance.total : _amount;
            }
        }
        else if (_type == DataTypes.TransactionType.REPAY)
        {
            if (balance.accruedInterest >= _amount)
                balance.accruedInterest -= _amount;
            else
            {
                _amount -= balance.accruedInterest;
                balance.accruedInterest = 0;

                returnValue = _amount < balance.total ? _amount : balance.total;

                // overpaying consider bonus to the protocol
                balance.total -= _amount > balance.total ? balance.total : _amount;
            }
        }
        else if (_type == DataTypes.TransactionType.LIQUIDATION)
        {
            _clearAfterLiqudation(balance);
        }
        else
            revert("Invalid transaction parameter");

        // update timestamp
        _updateTimestamp(balance);

        return returnValue;
    }

    /**
    * @dev Changes the interest mode of the balance, updates accrued interest and timestamp of getting executed
    * @param balance the _balance struct to change the interest mode in
    * @param _interest the interest mode to be changed to
    * @param _interestRate the new interest rate, important only in fixed interest Rate
    * @param reserve the reserve pool of the asset
    */
    function _changeInterestMode(
        _balance storage balance,
        DataTypes.InterestMode _interest,
        uint _interestRate,
        Reserve.ReserveData storage reserve
    ) internal {
        // update accrued interest
        _updateInterest(balance, reserve);

        balance.interestMode = _interest;

        balance.interestRate = _interestRate;

        //update timestamp
        _updateTimestamp(balance);
    }

    /**
    * Check, whether this instance of struct was initialized before or not
    * @param balance The struct to be checked
    * @return returns true if the struct is new or uninitialized, false if doesn't have some
    *   default values
    */
    function _isEmpty(_balance storage balance) internal view returns(bool)
    {
        if (_getInterestMode(balance) != DataTypes.InterestMode.NONE &&
            balance.accountType != DataTypes.BalanceType.NONE &&
            balance.collateral == address(0))
                return false;
        
        return true;
    }

    /**
    * @dev resets the collateral to address(0)
    * @param balance The struct to be checked
    */
    function _resetCollateral(_balance storage balance) internal
    {
        balance.collateral = address(0);
    }

    /**
    * @dev clears total, accrued interest and collateral asset address, should be called upon liquidation event
    * @param balance the struct to be cleared
    */
    function _clearAfterLiqudation(_balance storage balance) private
    {
        _resetCollateral(balance);
        balance.accruedInterest = 0;
        balance.total = 0;
    }

    /**
    * @dev updates the timestamp, should be called after every change
    */
    function _updateTimestamp(_balance storage balance) private
    {
        balance.timestamp = block.timestamp;    
    }

    /**
    * @dev calculates the interest, corresponding reserve pool needed
    * @param balance the struct for which we calculate interest
    * @param reserve the reserve pool of the asset
    * @return returns the interest since last change
    */
    function _calculateInterest(
        _balance storage balance,
        Reserve.ReserveData storage reserve
    ) private view returns(uint) {

        uint timePassed = block.timestamp - _getLastTimestamp(balance);
        uint timePrecision = 10**8;
        timePassed *= timePrecision;
        timePassed /= DataTypes.secondsPerYear;
        
        DataTypes.InterestMode interestTyp = _getInterestMode(balance);

        (uint varDeposit, uint fixDeposit, uint varBorrow, uint fixBorrow) = reserve.getInterests();

        uint interest = Interests.selectInterestRate(
            balance.accountType,
            interestTyp,
            varDeposit,
            fixDeposit,
            varBorrow,
            fixBorrow
        );

        if (interestTyp == DataTypes.InterestMode.FIXED)
            interest = balance.total * balance.interestRate;
        else if (interestTyp == DataTypes.InterestMode.VARIABLE)
            interest = balance.total * interest;
        
        interest /= 10**reserve.getDecimals();
        interest *= timePassed;
        interest /= timePrecision;
        
        return interest;
    }

    /**
    * @dev updates the accrued interest, should be called after every change
    */
    function _updateInterest(
        _balance storage balance,
        Reserve.ReserveData storage reserve
    ) private {
        balance.accruedInterest += _calculateInterest(balance, reserve);
    }
    
}