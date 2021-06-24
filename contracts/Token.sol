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
    
    uint internal constant ICO_AMOUNT = 3000000 ether;

    uint internal constant TEAM_AMOUNT = 4500000 ether;

    uint internal constant COMMUNITY_AMOUNT = 1500000 ether;

    uint internal constant REWARDS_AMOUNT = 21000000 ether;

    address public owner;

    event ChangeOwner(
        address indexed from,
        address indexed to,
        uint time
    );

    /**
    * only owner is able to access
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner of this contract can access this function");
        _;
    }

    /**
    * @notice minting tokens to the team, ico and community. For minting rewards use function mint()
    * @param _team the address of the team tokens are sent to
    * @param _ico the address of the ICO tokens are sent to
    * @param _community the address of the community tokens are sent to
    */
    constructor(address _team, address _ico, address _community) ERC20(NAME, SYMBOL){
        owner = msg.sender;
        _mint(_team, TEAM_AMOUNT);
        _mint(_ico, ICO_AMOUNT);
        _mint(_community, COMMUNITY_AMOUNT);
    }
    /**
    * Pass the owner role to another address, can be done only by prior owner
    * @param _newOwner the address of the new owner
    */
    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0), "New owner can't be zero address");
        owner = _newOwner;
        emit ChangeOwner(msg.sender, _newOwner, block.timestamp);
    }
    
    function maxSupply() public view returns(uint) {
        return _maxSupply;
    }

    /**
    * @notice owner is able to mint tokens to passed address, should be used only for minting rewards
    * @param _address the address of the rewarded
    * @param _amount to be send in gwei
    */
    function mint(address _address, uint _amount) onlyOwner public {
        require(_amount + totalSupply() < maxSupply(), "Owner trying to mint more than maxSupply");
        _mint(_address, _amount);
    }


}