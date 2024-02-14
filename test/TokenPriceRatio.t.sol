// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenPriceRatioTest is Test {
    Token public token;
    address owner = address(1);
    uint256 decimals;

    function setUp() public {}

    function setUpToken(uint256 curveRatio, uint256 initialBuy) internal {
        token = new Token(owner, "Curve Token", "TKN", 0, curveRatio);

        if (initialBuy > 0) {
            token.buy{value: initialBuy}(0);
        }
    }

    // Buy ratio

    function test_BuyRatio320000() public {
        setUpToken(320_000, 0);
        assertEq(token.calculateBuyReturn(1 ether), tokens(8));
        assertEq(token.calculateBuyReturn(100 ether), tokens(80));
    }

    function test_BuyRatio5000() public {
        setUpToken(5_000, 0);
        assertEq(token.calculateBuyReturn(1 ether), tokens(1));
        assertEq(token.calculateBuyReturn(10_000 ether), tokens(100));
    }

    function test_BuyRatio1000() public {
        setUpToken(2_500, 0);
        assertEq(token.calculateBuyReturn(2 ether), tokens(1));
        assertEq(token.calculateBuyReturn(20_000 ether), tokens(100));
    }

    // Sell ratio

    function test_SellRatio320000() public {
        setUpToken(320_000, 1 ether);
        assertEq(token.calculateSellReturn(tokens(8)), 1 ether);
    }

    function test_SellRatio5000() public {
        setUpToken(5_000, 1 ether);
        assertEq(token.calculateSellReturn(tokens(1)), 1 ether);
    }

    // Helpers

    function tokens(uint256 amount) internal view returns (uint256) {
        return amount * 10 ** token.decimals();
    }
}
