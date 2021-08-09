// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

import {DataTypes, Liquidations, Interests} from './Utils.sol';
import {Balance} from './Balance.sol';
import {Reserve} from './Reserve.sol';

/**
* @author Rastislav Budinsky
* @notice in UserConfig struct are 2 mappings   1) for balances of user's fund
*                                               2) for borrows of user
*   ! Be aware, to setup the balance struct for specific token first you must make a transaction
*           1) deposit
*           2) borrow
*       to be able to change interest mode or access any other function
*/
library UserConfiguration {

    using Balance for Balance._balance;
    using Reserve for Reserve.ReserveData;

    struct UserConfig {
        
        // (token.address => balance) balance of specific user
        mapping(address => Balance._balance) balances;

        // (token.address => borrow) borrows of specific user
        mapping(address => Balance._balance) borrows;
    }

    /**
    * @notice   DEFAULT: check the overall info of balance of token
    *           LENDING: check the overall info of borrow of token
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @return   DEFAULT: the overall info of the balance
    *           LENDING: the overall info of the borrow
    */
    function getInfo(
        UserConfig storage user,
        address token,
        Reserve.ReserveData storage reserve,
        DataTypes.BalanceType typ
    ) internal view returns(uint, uint, DataTypes.InterestMode, uint, address) {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._getInfo(reserve);
        
        return user.balances[token]._getInfo(reserve);
    }

    /**
    * @notice   DEFAULT: check the total deposited user's balance without any interest accounted in
    *           LENDING: check the total user's borrow without any interest accounted in
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @return   DEFAULT: the total balance
    *           LENDING: the total borrow
    */
    function getBalance(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ
    ) internal view returns(uint) {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._getBalance();
        else if (typ == DataTypes.BalanceType.DEFAULT)
            return user.balances[token]._getBalance();

        return 0;
    }

    /**
    * @notice   DEFAULT: check the total user's balance with interest
    *           LENDING: check the total borrow with interest
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @param reserve the reserve pool of the asset
    * @return   DEFAULT: the total balance with interest
    *           LENDING: the total borrow with interest
    */
    function getTotal(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ,
        Reserve.ReserveData storage reserve
    ) internal view returns(uint) {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._getTotal(reserve);
        else if (typ == DataTypes.BalanceType.DEFAULT)
            return user.balances[token]._getTotal(reserve);

        return 0;
    }

    /**
    * @notice check the last change of  DEFAULT: the user's balance
    *                                   LENDING: the total borrow
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @return the time of last change   DEFAULT: deposit/withdraw/change of interest mode
    *                                   LENDING: borrow/pay off/change of interest mode
    */
    function getLastAccess(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ
    ) internal view returns(uint) {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._getLastTimestamp();
        else if (typ == DataTypes.BalanceType.DEFAULT)
            return user.balances[token]._getLastTimestamp();

        return 0;
    }

    /**
    * @notice check the accrued interest of DEFAULT: the user's balance
    *                                       LENDING: the total borrow
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @param reserve the reserve pool of the asset
    * @return the accrued interest of   DEFAULT: the user's balance
    *                                   LENDING: the total borrow
    */
    function getAccruedInterest(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ,
        Reserve.ReserveData storage reserve
    ) internal view returns(uint) {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._getAccruedInterest(reserve);
        else if (typ == DataTypes.BalanceType.DEFAULT)
            return user.balances[token]._getAccruedInterest(reserve);

        return 0;
    }

    /**
    * @notice check the interest mode of    DEFAULT: the user's balance
    *                                       LENDING: the user's borrow
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @return the interest mode of  DEFAULT: the user's balance
    *                               LENDING: the user's borrow
    */
    function getInterestMode(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ
    ) internal view returns(DataTypes.InterestMode) {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._getInterestMode();
        else if (typ == DataTypes.BalanceType.DEFAULT)
            return user.balances[token]._getInterestMode();

        return DataTypes.InterestMode.NONE;
    }

    /**
    * @notice check the interest rate of    DEFAULT: the user's balance
    *                                       LENDING: the user's borrow
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @return the interest rate of  DEFAULT: the user's balance
    *                               LENDING: the user's borrow
    */
    function getInterestRate(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ
    ) internal view returns(uint)
    {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._getInterestRate();
        else if (typ == DataTypes.BalanceType.DEFAULT)
            return user.balances[token]._getInterestRate();
        
        return 0;
    }

    /**
    * @notice   DEFAULT: check the asset currently be borrowed and get collaterized by this asset
    *           LENDING: check the collateral asset of this borrow
    * @param user UserConfig os specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @return the address of    DEFAULT: borrowed asset, in case no active borrow address(0)
    *                           LENDING: collateral asset
    */
    function getCollateral(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ
    ) internal view returns(address) {
        if (typ == DataTypes.BalanceType.DEFAULT)
            return user.borrows[token]._getCollateral();
        else if (typ == DataTypes.BalanceType.LENDING)
            return user.balances[token]._getCollateral();
        
        return address(0);
    }

    /**
    * @notice add borrow transaction to the user's log, if first transaction, interest mode set to fixed
    *   before calling this function you should be sure it's collaterized
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param amount the amount in the native token to borrow
    * @param collateral sets collateral, if active loan must be the same as with the first borrow
    * @param reserve the reserve pool of the asset
    */
    function addBorrow(
        UserConfig storage user,
        address token,
        uint amount,
        address collateral,
        Reserve.ReserveData storage reserve
    ) internal {
        // if first transaction, initializes Balance
        if (user.borrows[token]._isEmpty())
            user.borrows[token]._initialize(DataTypes.BalanceType.LENDING, token);

        user.borrows[token]._addTransaction(token, amount, DataTypes.TransactionType.BORROW, collateral, reserve);
    }

    /**
    * @notice add deposit transaction to the user's log, if first transaction, interest mode set to fixed
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param amount the amount in the native token to deposit
    * @param reserve the reserve pool of the asset
    */
    function addDeposit(
        UserConfig storage user,
        address token,
        uint amount,
        Reserve.ReserveData storage reserve
    ) internal {
        // if first transaction, initializes Balance
        if (user.balances[token]._isEmpty() == true)
            user.balances[token]._initialize(DataTypes.BalanceType.DEFAULT, token);
        user.balances[token]._addTransaction(token, amount, DataTypes.TransactionType.DEPOSIT, address(0), reserve);
    }

    /**
    * @notice add repay transaction to the user's log, overpaying considered reward to the protocol
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param amount the amount in the native token to be repaid
    * @param reserve the reserve pool of the asset
    * @return returns actual repaid amount without interest
    */
    function addRepay(
        UserConfig storage user,
        address token,
        uint amount,
        Reserve.ReserveData storage reserve
    ) internal returns(uint){
        uint returnValue = user.borrows[token]._addTransaction(token, amount, DataTypes.TransactionType.REPAY, address(0), reserve);

        // reset collaterals if full debt repaid
        if (user.borrows[token]._getTotal(reserve) == 0)
        {
            user.borrows[token]._resetCollateral();
            user.balances[token]._resetCollateral();
        }

        return returnValue;
    }


    /**
    * @notice add withdraw transaction to the user's log, might revert if not enough balance
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param amount the amount in the native token to be withdrawn
    * @param reserve_token the reserve pool of the asset
    * @param reserve_borrow the reserve pool of the borrowed asset
    */
    function addWithdraw(
        UserConfig storage user,
        address token,
        uint amount,
        Reserve.ReserveData storage reserve_token,
        Reserve.ReserveData storage reserve_borrow
    ) internal {
        require(user.balances[token]._isEmpty() == false, "First transaction cannot be withdrawal");

            // check if can withdraw in collateral treshold
            address borrow = user.balances[token]._getCollateral();

            if (borrow != address(0))
            {
                // TODO add last 3 parameters
                require(Liquidations.checkLiquidated(
                    borrow,
                    user.borrows[borrow]._getTotal(reserve_borrow),       // interest counts
                    token,
                    user.balances[token]._getBalance(),     // interest doesn't count
                    0,
                    0,
                    0
                ) == DataTypes.LiquidationType.BORROWABLE, "Unable to withdraw too to high borrow/collateral risk");
            }

            user.balances[token]._addTransaction(token, amount, DataTypes.TransactionType.WITHDRAW, address(0), reserve_token);
    }

    /**
    * @notice add liquidation event to the user's log, clearing his balance and his borrow amount with the asset and it's respective collateral
    * @param user UserConfig of specific user
    * @param token the address of the borrowed asset
    * @param collateral the address of the collateral asset
    * @param reserve_token the reserve pool of the asset
    * @param reserve_collateral the reserve pool of the collateral
    */
    function addLiquidation(
        UserConfig storage user,
        address token,
        address collateral,
        Reserve.ReserveData storage reserve_token,
        Reserve.ReserveData storage reserve_collateral
    ) internal {
        user.borrows[token]._addTransaction(token, user.borrows[token]._getTotal(reserve_token), DataTypes.TransactionType.LIQUIDATION, address(0), reserve_token);
        user.balances[collateral]._addTransaction(collateral, user.balances[collateral]._getTotal(reserve_collateral), DataTypes.TransactionType.LIQUIDATION, address(0), reserve_collateral);
    }

    /**
    * @notice change the interest mode  DEFAULT: user's deposited balance
    *                                   LENDING: user's borrow
    * @param user UserConfig of specific user
    * @param token the address of the token to be checked
    * @param typ choose mode:   DEFAULT
    *                           LENDING
    * @param mode the new mode
    * @param reserve the reserve pool of the asset in the lending pool
    * @return returns the new interest rate for selected interest mode
    */
    function changeInterestMode(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ,
        DataTypes.InterestMode mode,
        Reserve.ReserveData storage reserve
    ) internal returns(uint) {

        (uint varDeposit, uint fixedDeposit, uint varBorrow, uint fixedBorrow) = reserve.getInterests();
        uint interestRate = Interests.selectInterestRate(typ, mode, varDeposit, fixedDeposit, varBorrow, fixedBorrow);

        if (typ == DataTypes.BalanceType.LENDING)
        {
            user.borrows[token]._changeInterestMode(mode, interestRate, reserve);
        }

        user.balances[token]._changeInterestMode(mode, interestRate, reserve);

        return interestRate;
    }

    /**
    * @notice Allows you to check, whether the  DEFAULT: user's balance is initialized
    *                                           LENDING: user's borrow is initialized
    * @param user UserConfig of the specific user
    * @param token the address of the token to be checked
    * @param typ choose     DEFAULT
    *                       LENDING
    * @return true if it was not yet initialized (is empty), false if already initialized
    */
    function isEmpty(
        UserConfig storage user,
        address token,
        DataTypes.BalanceType typ    
    ) internal view returns(bool) {
        if (typ == DataTypes.BalanceType.LENDING)
            return user.borrows[token]._isEmpty();

        return user.balances[token]._isEmpty();
    }
}