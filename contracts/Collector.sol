// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/safeERC20.sol";


contract Collector is Ownable {
    error noEthDeposited();
    error noEthToWithdraw();
    error noEthSent();
   
    uint public constant usdDecimals = 2;
    uint public ownerEthAmountToWithdraw;

    address public oracleEthUsdPrice;

    AggregatorV3Interface public ethUsdOracle;

    mapping(address user => uint256 amount) public userEthDeposits;

    /**
     * Network: ETH mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor(address clEthUsd) {
        oracleEthUsdPrice = clEthUsd;

        ethUsdOracle = AggregatorV3Interface(oracleEthUsdPrice);
    }

    /**
     * Returns the latest price
     */
     function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 round ID */,
            int price,
            /*uint startedAt */,
            /*uint timeStamp */,
            /*uint80 answeredInRound */
        ) = ethUsdOracle.latestRoundData();
        return price;
    }

    /** Native coins (ETH, Matic, avax,...) */
    receive() external payable {
        registeredUserDeposit(msg.sender);
    }

    function registeredUserDeposit(address sender) internal {
        if (msg.value == 0) {
            revert noEthSent();
        }
        userEthDeposits[sender] += msg.value;
    }

    function getPriceDecimals() public view returns (uint) {
        return uint(ethUsdOracle.decimals());
    }

    function convertEthInUSD(address user) public view returns (uint) {
        uint userUSDDeposit = 0;
        if (userEthDeposits[user] > 0) {
            uint ethPriceDecimals = getPriceDecimals();
            uint ethPrice = uint(getLatestPrice());     // scaled by 10^ethPriceDecimals (10^8)
            uint divDecs = 18 + ethPriceDecimals - usdDecimals;
            userUSDDeposit = userEthDeposits[user] * ethPrice / (10 ** divDecs);    // scaled by 10^26 / 10^24 = 10^2
        }
        return userUSDDeposit;
    }

    function convertUSDInETH(uint usdAmount) public view returns (uint) {
        uint convertAmountInEth = 0;
        if (usdAmount> 0) {
            uint ethPriceDecimals = getPriceDecimals();
            uint ethPrice = uint(getLatestPrice()); // scaled by 10^ethPriceDecimals (10^8)
            uint mulDecs = 18 + ethPriceDecimals - usdDecimals;
            convertAmountInEth = usdAmount * (10 ** mulDecs) / ethPrice;    // scaled by 10^26 / 10^8 = 10^18
        }

        return convertAmountInEth;
    }

    /** this balance in native coins and token */
    function getNativeCoinsBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /** Withdraws */
    function userETHWithdraw() external {
        if(userEthDeposits[msg.sender] == 0) {
            revert noEthDeposited();
        }
        uint tempValue = userEthDeposits[msg.sender];
        userEthDeposits[msg.sender] = 0;

        (bool sent, ) = payable(_msgSender()).call{value: tempValue}("");
        if (!sent) {
            revert noEthSent();
        }
    }
}