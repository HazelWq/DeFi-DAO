// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./AggregatorV3Interface.sol";

contract Trader {

    // Declare state variables of the contract
    address public owner;
    mapping (address => uint) public ETHreserve;
    mapping(uint256=>bool) btcRequests;
    mapping(uint256=>bool) ethRequests;
    uint public BTCposition;
    uint public BTCETHprice;

    AggregatorV3Interface internal ethFeed;
    bytes32 ethHash = keccak256(abi.encodePacked("ETH"));

    // When 'Trader' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's ETH balance to 5
    constructor() {
        owner = msg.sender;
        ETHreserve[address(this)] = 0;
        BTCposition = 0;
        BTCETHprice = 20;
        ethFeed = AggregatorV3Interface(0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22);
    }

    // Allow the owner to increase the smart contract's ETH balance
    function refill(uint amount) public payable {
        // require(msg.sender == owner, "Only the owner can refill."); 
        // Need Qi and Wei to donate together to have 5 ETH in total
        ETHreserve[address(this)] += amount;
    }

    // Allow anyone to trade Bitcoins
    function purchase() public payable {

        require(msg.value >= 0.01 ether, "You must pay jointly at least 0.01 ether to buy bitcoins");
        // require(reserve[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        ETHreserve[address(this)] -= msg.value;
        ETHreserve[msg.sender] += msg.value;
        BTCposition = msg.value / BTCETHprice;
    }

    // Oracle get Bitcoin price BTC/ETH

    function getBTCETHPrice() public returns (int) {
        (,
        int price,
        ,
        ,
        ) = ethFeed.latestRoundData();
        BTCETHprice = uint(price)/10**18;
        return price;
    }

}