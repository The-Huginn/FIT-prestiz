/**
* @author Rastislav Budinsky
* @file Token.sol
* @date 22.6.2021
* This file contains declaration of Token contract
*/

pragma solidity ^0.7.5;

import {ERC20} from '../open-zeppelin/ERC20.sol';

/**
* @author Rastislav Budinsky
* implementing contract of FITCOIN token
*/
contract Token is ERC20 {
    string internal constant NAME = "FIT coin";
    string internal constant SYMBOL = "FITCOIN";
    uint8 internal constant DECIMALS = 18;
    uint internal constant _maxSupply = 30000000 ether;
    
    uint internal constant ICO_AMOUNT = 4500000 ether;

    uint internal constant TEAM_AMOUNT = 4500000 ether;

    uint internal constant PROTOCOL_AMOUNT = 21000000 ether;

    /**
    * @notice minting tokens to the team, ico and community. For minting rewards use function mint()
    * @param _team the address of the team tokens are sent to
    * @param _ico the address of the ICO tokens are sent to
    * @param _protocol the address of the protocol tokens are sent to
    */
    constructor(address _team, address _ico, address _protocol) ERC20(NAME, SYMBOL){
        _mint(_team, TEAM_AMOUNT);
        _mint(_ico, ICO_AMOUNT);
        _mint(_protocol, PROTOCOL_AMOUNT);
    }
    
    function maxSupply() public view returns(uint) {
        return _maxSupply;
    }


}