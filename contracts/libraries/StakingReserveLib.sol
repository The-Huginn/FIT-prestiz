// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

library StakingReserveLib {

    struct StakingReserve {
        // the total amount staked
        uint total;

        // the current epoch for rewards
        uint payoutNumber;

        // the history of interest per 1 Token
        uint[] rewards;

        // the decimals of the token
        uint decimals;
    }

    function getTotal(StakingReserve storage stakingReserve) internal view returns(uint)
    {
        return stakingReserve.total;
    }

    /**
    * @notice initialized staking reserve
    * @param stakingReserve the staking reserve to be initialized
    * @param decimals the decimal precision of the token
    */
    function initializeStakingReserve(
        StakingReserve storage stakingReserve,
        uint decimals
    ) internal {
        stakingReserve.decimals = decimals;
        stakingReserve.rewards.push(0);
    }

    /**
    * @notice add stake to the staking reserve
    * @param stakingReserve the staking reserve to which is stake added
    * @param amountBefore the amount staked before this change, to calculate interest
    * @param amountAdded the amount added to the staking reserve
    * @param payoutStart since the last change, last epoch
    * @return returns the interest accrued before the stake
    * @return returns the epoch from which starts the interest
    */
    function stakeToReserve(
        StakingReserve storage stakingReserve,
        uint amountBefore,
        uint amountAdded,
        uint payoutStart
    ) internal returns(uint, uint){
        stakingReserve.total += amountAdded;

        return calculateInterest(stakingReserve, amountBefore, payoutStart);
    }

    /**
    * @notice add unstake from the staking reserve
    * @param stakingReserve the staking reserve from which is unstaked
    * @param amountBefore the amount before this change, to calculate interest
    * @param amountRemoved the amount removed from the staking reserve
    * @param payoutStart since the last change, last epoch
    * @return returns the accrued interest
    * @return returns the start of the new epoch for accruing interest
    */
    function unstakeFromReserve(
        StakingReserve storage stakingReserve,
        uint amountBefore,
        uint amountRemoved,
        uint payoutStart
    ) internal returns(uint, uint) {
        stakingReserve.total -= amountRemoved;
        
        return calculateInterest(stakingReserve, amountBefore, payoutStart);
    }

    /**
    * @notice add reward drop to the stakers
    * @param stakingReserve the staking reserve getting drops in it's currency
    * @param amount the amount getting rewarded to the stakers
    */
    function rewardToReserve(
        StakingReserve storage stakingReserve,
        uint amount
    ) internal {
        uint staked = stakingReserve.total / 10**stakingReserve.decimals;
        
        // not the best solution, as if there is staked below 1 token, then not the whole reward is distributed, e.g. only total/decimals * amount
        if (staked == 0)
            staked = 1;

        // if array empty, start with 0 otherwise get value from epoch before
        uint rewardPerToken = stakingReserve.rewards.length == 0 ? 0 : stakingReserve.rewards[stakingReserve.rewards.length - 1];
        rewardPerToken += ((amount * 10**stakingReserve.decimals) / staked) / 10**stakingReserve.decimals;

        // move into the next epoch
        stakingReserve.rewards.push(rewardPerToken);
        stakingReserve.payoutNumber++;
    }

    /**
    * @dev calculates the interest between epochs
    * @param stakingReserve the staking reserve to calculate the interest from
    * @param amount the amount staked between
    * @param payoutStart the starting epoch
    * @return returns the accrued interest
    * @return returns the next epoch
    */
    function calculateInterest(
        StakingReserve storage stakingReserve,
        uint amount,
        uint payoutStart
    ) internal view returns(uint, uint) {
        // unstaking at the same epoch
        if (payoutStart >= stakingReserve.payoutNumber)
            return (0, stakingReserve.payoutNumber);
        
        uint accruedInterest = (amount * 10**stakingReserve.decimals) *
                (stakingReserve.rewards[stakingReserve.payoutNumber] - stakingReserve.rewards[payoutStart]) /
                ((10**stakingReserve.decimals)**2);

        return (accruedInterest, stakingReserve.payoutNumber);
    }
}