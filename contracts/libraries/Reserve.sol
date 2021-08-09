// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

/**
* @author Rastislav Budinsky
* @dev library Reserve implementing struct for reserve pool and function to operate
*   with the pool, update it's state and variables, all fixed interest multipliers, healtgRate, decimals
*   shoul be initialized on launch of the reserve pool and shouldn't be changed, for proper functioning
*   as some libraries can store older interests with older decimal precisions for example
*/
library Reserve {

    struct ReserveData {

        // total available balance in protocol
        uint total;

        // total borrow
        uint borrow;

        // variable borrow interest
        uint variableBorrowInterest;

        // fixed borrow interest multiplier of variable
        uint fixedBorrowInterest;

        // variable deposit interest
        uint variableDepositInterest;

        // fixed deposit interest multiplier of variable
        uint fixedDepositInterest;

        // rate of deposit and borrow
        uint depositBorrowRate;

        // rate of volatility
        uint healthRate;

        // decimals of interests
        uint decimals;

        // true if deposit is available
        bool isDeposit;

        // true if borrow is available
        bool isBorrow;

        // true if reserve available at all
        bool isAvailable;

        // timestamp of the last update except variable interest rates and totals
        uint lastUpdate;
    }

    /**
    * @dev initialization function for the pool
    * @param reserve the reserve to be initialized
    * @param total the initial available balance in the protocol
    * @param fixedBorrowInterest the fixed interest multiplier relative to the variable borrow interest, should be in % multiplied by 10**decimals
    * @param fixedDepositInterest the fixed interest multiplier relative to the variable deposit interest, should be in % multiplied by 10**decimals
    * @param depositBorrowRate the rate at which borrowing has higher interest
    * @param healthRate the volatility rate of the reserve pool
    * @param decimals the decimal precision for interest
    */
    function initializeReserve(
        ReserveData storage reserve,
        uint total,
        uint fixedBorrowInterest,
        uint fixedDepositInterest,
        uint depositBorrowRate,
        uint healthRate,
        uint decimals
    ) internal {
        reserve.total = total;
        reserve.fixedBorrowInterest = fixedBorrowInterest;
        reserve.fixedDepositInterest = fixedDepositInterest;
        reserve.depositBorrowRate = depositBorrowRate;
        reserve.healthRate = healthRate;
        reserve.decimals = decimals;
    }

    /**
    * @dev initialization function for the reserve availability
    * @param isDeposit the initial state of availability of deposits
    * @param isBorrow the initial state of availability of borrows
    * @param isAvailable the initial state of availability of the reserve pool
    */
    function initializeAvailability(
        ReserveData storage reserve,
        bool isDeposit,
        bool isBorrow,
        bool isAvailable
    ) internal {
        reserve.isDeposit = isDeposit;
        reserve.isBorrow = isBorrow;
        reserve.isAvailable = isAvailable;
    }

    function getDecimals(ReserveData storage reserve) internal view returns(uint)
    {
        return reserve.decimals;
    }

    /**
    * @dev returns all bool regarding the availability of reserve
    * @param reserve the reserve to be checked
    * @return the overall availability
    * @return the deposit availability
    * @return the borrow availability
    */
    function checkAvailability(
        ReserveData storage reserve
    ) internal view returns(bool, bool, bool) {
        return (reserve.isAvailable, reserve.isDeposit, reserve.isBorrow);
    }

    /**
    * @dev try to realize deposit, on success recalculates interests
    * @param reserve the reserve to be checked
    * @param amount the to be deposited
    */
    function depositToReserve(
        ReserveData storage reserve,
        uint amount
    ) internal {
        (bool available, bool depositAvailable, ) = checkAvailability(reserve);

        require(available, "The reserve is unavailable");
        require(depositAvailable, "The deposit to this reserve is unavailable");

        reserve.total += amount;

        updateInterests(reserve);
    }

    /**
    * @dev try to realize borrow on success recalculates interests
    * @param reserve the reserve to be checked
    * @param amount the amount to be borrowed
    */
    function borrowFromReserve(
        ReserveData storage reserve,
        uint amount
    ) internal {
        (bool available, , bool borrowAvailable) = checkAvailability(reserve);

        require(available, "The reserve is unavailable");
        require(borrowAvailable, "The borrow for this reserve is unavailable");
        require(reserve.total > amount, "Reserve doesn't have enough collateral");

        reserve.total -= amount;
        reserve.borrow += amount;

        updateInterests(reserve);
    }

    /**
    * @dev accepts the withdraw and recalculates interests
    * @param reserve the reserve to be checked
    * @param amount the amount to be withdrawn
    */
    function withdrawFromReserve(
        ReserveData storage reserve,
        uint amount
    ) internal {
        (bool available, , ) = checkAvailability(reserve);

        require(available, "The reserve is unavailable");
        require(reserve.total >= amount, "The reserve doesn't have enough balance");

        reserve.total -= amount;

        updateInterests(reserve);
    }

    /**
    * @dev accepts the repayment and recalculates interests
    * @param reserve the reserve to be checked
    * @param amount the amount to be repaid
    */
    function repayToReserve(
        ReserveData storage reserve,
        uint amount
    ) internal {
        (bool available, , ) = checkAvailability(reserve);
        
        require(available, "The reserve is unavailable");
        
        reserve.total += amount;
        reserve.borrow -= amount;

        updateInterests(reserve);
    }

    /**
    * @dev returns actual interest rates
    * @param reserve the reserve to be checked
    * @return variable deposit interest rate
    * @return fixed deposit interest rate
    * @return variable borrow interest rate
    * @return fixed borrow interest rate
    */
    function getInterests(
        ReserveData storage reserve
    ) internal view returns(uint, uint, uint, uint) {
        return (
            reserve.variableDepositInterest,
            reserve.fixedDepositInterest * reserve.variableDepositInterest / 10**reserve.decimals,
            reserve.variableBorrowInterest,
            reserve.variableBorrowInterest + reserve.fixedBorrowInterest * (reserve.variableBorrowInterest) / 10**reserve.decimals
        );
    }

    event Interests(uint variableDeposit, uint fixedDeposit, uint variableBorrow, uint fixedBorrow);
    /**
    * @dev recalculates interest rates
    * @param reserve the reserve to be checked
    */
    function updateInterests(
        ReserveData storage reserve
    ) private {
        uint deposit = reserve.total + reserve.borrow;
        uint borrow = reserve.borrow;

        if (borrow == 0)
        {
            reserve.variableBorrowInterest = 0;
            reserve.variableDepositInterest = 0;
            return;
        }

        uint decimals = 10**reserve.decimals;

        borrow *= decimals;

        // 1 equals to 1000000; 0.5 to 500000 etc
        uint rate = borrow / deposit;
        
        // function 0.15 - 0.15 / (1 + 2x) gives result between 0 to 1 on map 0 to 1
        uint a = 150000;
        uint b = 150000;

        rate *= 2;
        rate += decimals;

        b *= decimals;
        b /= rate;
        
        a -= b;         // a now holds the final result

        // 'a' * (decimals -  reserve.healthRate) helps to leave a small margin for error instead of just using 'a'
        reserve.variableDepositInterest = (a * (decimals - reserve.healthRate)) / decimals;

        // same as above, helps to get a bit more for future
        reserve.variableBorrowInterest = (deposit * a) * (decimals + reserve.healthRate) / borrow;

        emit Interests(
            reserve.variableDepositInterest,
            reserve.fixedDepositInterest * reserve.variableDepositInterest / 10**reserve.decimals,
            reserve.variableBorrowInterest,
            reserve.variableBorrowInterest + reserve.fixedBorrowInterest * (reserve.variableBorrowInterest) / 10**reserve.decimals
        );
    }
}