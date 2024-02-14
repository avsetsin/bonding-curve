// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenSellTest is Test {
    Token public token;
    address owner = address(1);
    address account = address(2);

    function setUp() public {
        token = new Token(owner, "Curve Token", "TKN", 0, 5_000);
    }

    // Sell

    function test_Sell1Token() public {
        uint256 buyAmount = tokens(1);
        uint256 ethAmount = 1 ether;

        buyTokens(account, ethAmount, buyAmount);

        vm.prank(account);
        token.sell(buyAmount);

        assertEq(token.balanceOf(account), 0);
        assertEq(account.balance, ethAmount);
    }

    function test_Sell100Token() public {
        uint256 buyAmount = tokens(100);
        uint256 ethAmount = 10_000 ether;

        buyTokens(account, ethAmount, buyAmount);

        vm.prank(account);
        token.sell(buyAmount);

        assertEq(token.balanceOf(account), 0);
        assertEq(account.balance, ethAmount);
    }

    // Sell huge amount

    function test_SellHugeAmount() public {
        uint256 buyAmount = tokens(10_000_000_000);
        uint256 ethAmount = 100_000_000_000_000_000_000 ether;

        buyTokens(account, ethAmount, buyAmount);

        vm.prank(account);
        token.sell(buyAmount);

        assertEq(token.balanceOf(account), 0);
        assertEq(account.balance, ethAmount);
    }

    function test_SellEmitEvent() public {
        vm.skip(true);
        // TODO
    }

    // Buy and sell rounded amount

    function test_BuyAndSellRoundedAmount() public {
        vm.startPrank(account);

        uint256 ethAmount = 1 ether + 10 wei;

        vm.deal(account, ethAmount);
        token.buy{value: ethAmount}(0);

        uint256 balance = token.balanceOf(account);
        token.sell(balance);

        assertGt(address(token).balance, 0);
        assertEq(token.totalSupply(), 0);

        vm.stopPrank();
    }

    function test_BuyAndSellMultiplyTimes() public {
        vm.startPrank(account);
        vm.deal(account, 100 ether);

        token.buy{value: 1 ether}(0);
        token.buy{value: 2 ether}(0);
        token.buy{value: 3 ether}(0);

        uint256 balance = token.balanceOf(account);

        token.sell(balance / 5);
        token.sell(balance / 3);
        token.sell(token.balanceOf(account));

        assertGt(address(token).balance, 0);
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(account), 0);

        vm.stopPrank();
    }

    // Helpers

    function tokens(uint256 amount) internal view returns (uint256) {
        return amount * 10 ** token.decimals();
    }

    function buyTokens(address toAccount, uint256 ethAmount, uint256 buyAmount) internal {
        vm.deal(toAccount, ethAmount);
        vm.prank(toAccount);
        token.buy{value: ethAmount}(buyAmount);
        assertEq(token.balanceOf(toAccount), buyAmount);
    }
}
