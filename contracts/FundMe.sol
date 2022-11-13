// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner(); // two underscores

/** @title A contract for crowd funding
 *  @author Kazuki Hashimoto
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as library
 */
contract FundMe{
    using PriceConverter for uint256;

    mapping (address => uint256) private s_addressToAmountFunded;  // s_ means storage variable
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // USD
    AggregatorV3Interface private s_priceFeed;

    // modifier should be set before functions
    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if(msg.sender != i_owner) { revert FundMe__NotOwner(); }
        _; // reset of codes
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure
    
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // What happens if someone send this contract ETH without calling the fund function
    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /** 
     *  @notice This function funds this contract
     *  @dev This implements price feeds as library
     */
    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we sent ETH to this contract?
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need more ETH!"); // 1e18 == 1 * 10 ** 18
        // 18 decimals

        // What is reverting?
        // undo any action before, and send remainning gas back

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // for(starting index, ending index, step amount)
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0); // (i) means there are i objects in this array

        // actually withdraw the funds
        // there are three ways
        // 1. transfer
         // msg.sender == address
         // payable(address) == payable address
        // payable(msg.sender).transfer(address(this).balance);
        // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // if failed, it will not revert transaction
        // require(sendSuccess, "Send failed");
        // 3. call recommended
        (bool callSuccess, /* bytes memory dataReturned */) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mapping cannot be in memory

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // getter functions save gas cost
    /// because private is cheaper than public
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

}