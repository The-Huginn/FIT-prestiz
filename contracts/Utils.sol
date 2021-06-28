pragma solidity ^0.7.5;

library DataTypes {
    
    enum TransactionType {NONE, DEPOSIT, WITHDRAW, BORROW, REPAY}

    enum InterestMode {NONE, FIXED, VARIABLE}

    enum BalanceType {NONE, DEFAULT, LENDING}
}

library Transaction {

    

}

library Interest {

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