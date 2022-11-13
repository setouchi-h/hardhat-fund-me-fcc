// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// install by "yarn add --dev @chainlink/contracts"
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library cannot have any state variables and cannot send ETH
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); // not need this, because we received it
        (, int256 price,,,) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // ethPrice * ethAmount だけだと32decimalになる
        return ethAmountInUsd;
    }
}