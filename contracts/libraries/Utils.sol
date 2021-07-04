pragma solidity ^0.7.5;

library DataTypes {
    
    enum TransactionType {NONE, DEPOSIT, WITHDRAW, BORROW, REPAY, STAKE, UNSTAKE, STAKE_REWARD, SLASH}

    enum InterestMode {NONE, FIXED, VARIABLE}

    enum BalanceType {NONE, DEFAULT, LENDING}

    enum LiquidationType {NONE, BORROWABLE, UNBORROWABLE, LIQUIDATED}
}

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
}

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

    // struct BalanceSnap {
    //     uint _timestamp;        // since last interaction
    //     address _token;         // smart contract address of the token
    //     uint _borrowAmount;     // initial borrow
    //     uint _accruedInterest;  // total accrued interest
    //     uint _interest;         // interest, in variable mode should be recalculated
    //     InterestMode _interestMode;
    // }

    // /**
    // * @dev Calculates the increse in interest since last provided snap
    // * @param _snap The snap to calculate interest since
    // * @return The previous total debt, the current total dept, accrued interest since last interact
    // */
    // function balanceIncrease(BalanceSnap storage _snap) 
    //     internal
    //     view
    //     returns(
    //         uint,
    //         uint,
    //         uint
    //     )
    // {
    //     uint interest = _snap._interestMode == InterestMode.VARIABLE ? calcVariableInterest() : _snap._interest;
    //     uint accruedInterest = ( block.timestamp - _snap._timestamp ) * interest;

    //     return(
    //         _snap._borrowAmount + _snap._accruedInterest,
    //         _snap._borrowAmount + _snap._accruedInterest + accruedInterest,
    //         accruedInterest
    //     );
    // }

    // /**
    // * @dev Calculates current variable APY for borrow
    // */
    // function calcVariableInterest()
    //     internal
    //     view
    //     returns(uint)
    // {
    //     // TODO
    //     return 0;
    // }
}