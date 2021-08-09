// SPDX-License-Identifier: 0BSD

pragma solidity ^0.7.5;

interface IPriceAggregator {

    /**
    * @dev returns price in ETH
    */
    function getAssetPrice(address _asset) external view returns(uint);
}