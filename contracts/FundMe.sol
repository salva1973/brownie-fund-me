// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    //using SafeMathChainlink for uint256;

    // keep track of who sent the payment
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;
    
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // 50$
        uint256 minimumUSD = 50 * 10 ** 18; // since we want Wei
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");

        // 1 gwei < 50$
        addressToAmountFunded[msg.sender] += msg.value;
        // what the ETH -> USD conversion rate

        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {        
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) { // price of Eth in USD with 18 decimals        
        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000); // Normalization (from Wei to Eth)
    }

    // 10000000000 Wei?
    function getConversionRate(uint256 ethAmount) public view  returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    } 

    function getEntranceFee() public view returns (uint256) {
      // minimumUSD
      uint256 minimumUSD = 50 * 10**18;
      uint256 price = getPrice();
      uint256 precision = 1 * 10**18;
      return (minimumUSD * precision) / price;
      return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner {
        require(msg.sender == owner); // we could include a reason after comma
        _; // run the rest of the code here
    }

    function withdraw() payable onlyOwner public {             
        // only want the contract admin/owner        
        payable(msg.sender).transfer(address(this).balance); // send all money that's been funded
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}