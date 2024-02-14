// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {CoolDown} from "./CoolDown.sol";

/**
 * @title Token Contract
 * @dev A contract representing a token with a bonding curve mechanism
 */
contract Token is ERC20, CoolDown {
    uint256 public immutable PRICE_RATIO_DENOMINATION = 10_000;
    uint256 public immutable PRICE_RATIO;

    event Bought(address indexed account, uint256 ethAmount, uint256 buyAmount);
    event Sold(address indexed account, uint256 ethAmount, uint256 sellAmount);

    error TooMuchAmountToBuy(uint256 minBuyAmount, uint256 buyAmount);
    error ZeroBuyAmount();

    /**
     * @dev Contract constructor
     * @param owner The address of the contract owner
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param coolDownTime The cooldown time for token transfers
     * @param priceRatio The price ratio for the bonding curve
     */
    constructor(address owner, string memory name, string memory symbol, uint256 coolDownTime, uint256 priceRatio)
        ERC20(name, symbol)
        CoolDown(coolDownTime)
        Ownable(owner)
    {
        PRICE_RATIO = priceRatio;
    }

    /**
     * @dev Buy tokens from the bonding curve
     * @param minBuyAmount The minimum amount of tokens to buy
     */
    function buy(uint256 minBuyAmount) public payable {
        uint256 buyAmount = calculateBuyReturn(msg.value);
        if (buyAmount == 0) revert ZeroBuyAmount();
        if (minBuyAmount > buyAmount) revert TooMuchAmountToBuy(minBuyAmount, buyAmount);

        _setCoolDown(_msgSender());
        _mint(_msgSender(), buyAmount);

        _assertContractBalance();

        emit Bought(_msgSender(), msg.value, buyAmount);
    }

    /**
     * @dev Sell tokens to the bonding curve
     * @param sellAmount The amount of tokens to sell
     */
    function sell(uint256 sellAmount) public {
        uint256 ethAmount = calculateSellReturn(sellAmount);

        _burn(_msgSender(), sellAmount);
        Address.sendValue(payable(_msgSender()), ethAmount);

        _assertContractBalance();

        emit Sold(_msgSender(), ethAmount, sellAmount);
    }

    /**
     * @dev Calculate the amount of tokens to buy based on the provided ETH amount
     * @param ethAmount The amount of ETH used to buy tokens
     * @return buyAmount The amount of tokens to buy
     */
    function calculateBuyReturn(uint256 ethAmount) public view returns (uint256 buyAmount) {
        // ethAmount = priceForTokens * buyAmount
        // priceForTokens = (totalSupply + totalSupply + buyAmount) / 2 * ratio
        // ethAmount = (totalSupply + totalSupply + buyAmount) / 2 * ratio * buyAmount
        //
        //   price
        //   ^
        //   |          _
        //   |        _|+|
        //   |      _|+|+|
        //   |    _| |+|+|
        //   |  _| | |+|+|
        //   |_| | | |+|+|
        //   -----------------> totalSupply
        //           ^   ^
        //           ^   totalSupply + buyAmount
        //           totalSupply
        //
        // Derive the quadratic equation:
        // buyAmount**2 + (2 * totalSupply) * buyAmount - 2 * ethAmount / ratio = 0
        //
        // Or:
        // a * x**2 + b * x + c = 0
        //
        // Where:
        // x = buyAmount
        // a = 1
        // b = 2 * totalSupply
        // c = - 2 * ethAmount / ratio

        uint256 totalSupply = totalSupply();

        uint256 b = 2 * totalSupply;
        uint256 negativeC = 2 * ethToToken(ethAmount) * 10 ** decimals() * PRICE_RATIO / PRICE_RATIO_DENOMINATION;

        // d = b ** 2 - 4 * a * c
        // d = b ** 2 + 4 * a * (-c)
        uint256 discriminant = b ** 2 + 4 * negativeC;

        // x1 = (-b + sqrt(discriminant)) / (2 * a)
        // x2 = (-b - sqrt(discriminant)) / (2 * a)   predictably negative
        buyAmount = (Math.sqrt(discriminant) - b) / 2;
    }

    /**
     * @dev Calculate the amount of ETH to receive when selling the specified amount of tokens.
     * @param sellAmount The amount of tokens to sell.
     * @return ethAmount The amount of ETH to receive.
     */
    function calculateSellReturn(uint256 sellAmount) public view returns (uint256 ethAmount) {
        // ethAmount = priceForTokens * sellAmount
        // priceForTokens = (totalSupply + totalSupply - sellAmount) / 2 * ratio
        // ethAmount = (totalSupply + totalSupply - sellAmount) / 2 * ratio * sellAmount
        //
        //   price
        //   ^
        //   |          _
        //   |        _|-|
        //   |      _|-|-|
        //   |    _| |-|-|
        //   |  _| | |-|-|
        //   |_| | | |-|-|
        //   -----------------> totalSupply
        //           ^   ^
        //           ^   totalSupply
        //           totalSupply - sellAmount

        uint256 ethAmountDenominatedInTokens = (2 * totalSupply() - sellAmount) * sellAmount * PRICE_RATIO_DENOMINATION
            / PRICE_RATIO / 10 ** decimals() / 2;

        ethAmount = tokenToEth(ethAmountDenominatedInTokens);
    }

    /**
     * @dev Convert an ETH amount to token amount
     * @param amount The amount of ETH to convert
     * @return amount The equivalent amount of tokens
     */
    function ethToToken(uint256 amount) public view returns (uint256) {
        return amount * 10 ** decimals() / 1 ether;
    }

    /**
     * @dev Convert a token amount to ETH amount
     * @param amount The amount of tokens to convert
     * @return amount The equivalent amount of ETH
     */
    function tokenToEth(uint256 amount) public view returns (uint256) {
        return amount * 1 ether / 10 ** decimals();
    }

    /**
     * @dev Assert the contract has enough balance to cover the total supply
     */
    function _assertContractBalance() internal view {
        assert(address(this).balance >= calculateSellReturn(totalSupply()));
    }

    /**
     * @inheritdoc ERC20
     */
    function _update(address from, address to, uint256 value) internal override {
        _checkCoolDownPassed(from);
        super._update(from, to, value);
    }
}
