pragma solidity ^0.7.5;

/**
* @author Rastislav Budinsky
* @dev library declaring all used enums at the moment in the DataTypes library
*/
library DataTypes {
    
    enum TransactionType {NONE, DEPOSIT, WITHDRAW, BORROW, REPAY, LIQUIDATION, STAKE, UNSTAKE, STAKE_REWARD_FITCOIN, STAKE_REWARD_OTHER, STAKE_REDEEM, SLASH}

    enum InterestMode {NONE, FIXED, VARIABLE}

    enum BalanceType {NONE, DEFAULT, LENDING}

    enum LiquidationType {NONE, BORROWABLE, UNBORROWABLE, LIQUIDATED}

    uint public constant secondsPerYear = 31536000;
}

/**
* @author Rastislav Budinsky
* @dev utility library for calculating liquidations
*/
library Liquidations {

    /**
    * @notice checks, if the liquidation treshold is exceeded
    * @param asset the address of the borrowed asset
    * @param amount1 the amount of the borrowed asset
    * @param collateral the address of the underlying asset
    * @param amount2 the amount of collateral
    * @param liquidation the treshold before liquidation of this pair
    * @param borrow the treshold before the borrow is denied
    * @param decimals the decimal precision of liquidation and borrow tresholds
    * @return LiquidationType   BORROWABLE: if the user is allowed to borrow
    *                           UNBORROWABLE: the user is not allowed to borrow but not yet liquidated
    *                           LIQUIDATED: the user should get liquidated
    */
    function checkLiquidated(
        address asset,
        uint amount1,
        address collateral,
        uint amount2,
        uint liquidation,
        uint borrow,
        uint decimals
    ) public view returns(DataTypes.LiquidationType) {

        return DataTypes.LiquidationType.BORROWABLE;
    }

    /**
    * @notice calculates the liquidation price
    * @param asset the address of the borrowed asset
    * @param amount1 the amount of the borrowed asset
    * @param collateral the address of the underlying asset
    * @param amount2 the amount of the underlying asset
    * @param liquidation the treshold before liquidation of this pair
    * @param decimals the decimal precision of liquidation
    * @return returns the price at which the underlying asset if liquidated
    */
    function getLiquidationPrice(
        address asset,
        uint amount1,
        address collateral,
        uint amount2,
        uint liquidation,
        uint decimals
    ) public view returns(uint) {

        return 0;
    }
}

/**
* @author Rastislav Budinsky
* @dev utility library for selecting interests*/
library Interests {

    /**
    * @dev selects the proper interest rate
    * @param balanceType the type of balance
    * @param interestMode the interest mode selected
    * @param variableDeposit the variable deposit interest rate
    * @param fixedDeposit the fixed deposit interest rate
    * @param variableBorrow the variable borrow interest rate
    * @param fixedBorrow the fixed borrow interest rate
    * @return returns the interest rate accordingly
    */
    function selectInterestRate(
        DataTypes.BalanceType balanceType,
        DataTypes.InterestMode interestMode,
        uint variableDeposit,
        uint fixedDeposit,
        uint variableBorrow,
        uint fixedBorrow 
    ) internal view returns(uint) {
        if (balanceType == DataTypes.BalanceType.LENDING)
        {
            return interestMode == DataTypes.InterestMode.FIXED ? fixedBorrow : variableBorrow;
        }

        return interestMode == DataTypes.InterestMode.FIXED ? fixedDeposit : variableDeposit;
    }

}