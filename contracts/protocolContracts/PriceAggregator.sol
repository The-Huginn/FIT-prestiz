// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

import '../interfaces/IPriceAggregator.sol';
// import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

contract PriceAggregator is IPriceAggregator {
    
    // AggregatorV3Interface internal priceFeed;

    constructor() public {
        // priceFeed = AggregatorV3Interface(0xd04647B7CB523bb9f26730E9B6dE1174db7591Ad);
    }

    function getAssetPrice(address _asset) public override view returns(uint) {
        // (
        //     ,
        //     int price,
        //     ,
        //     ,

        // ) = priceFeed.latestRoundData();
        // return uint(price);
        return 0;
    }
}