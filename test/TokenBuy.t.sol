// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenBuyTest is Test {
    Token public token;
    address owner = address(1);
    uint256 decimals;

    function setUp() public {
        token = new Token(owner, "Curve Token", "TKN", 0, 5_000);
        decimals = token.decimals();
    }

    function test_InitialState() public {
        assertEq(token.totalSupply(), 0);
    }

    // Buy nothing

    function test_Buy0() public {
        vm.expectRevert(abi.encodeWithSelector(Token.ZeroBuyAmount.selector));
        token.buy{value: 0}(0);
    }

    function test_BuySomeWithoutValue() public {
        vm.expectRevert(abi.encodeWithSelector(Token.ZeroBuyAmount.selector));
        token.buy{value: 0}(tokens(1));
    }

    // Buy protection

    function test_BuyWithoutProtection() public {
        token.buy{value: 1 ether}(0);
        assertFirstBuy(address(this), tokens(1));
    }

    function test_BuyOverProtection() public {
        vm.expectRevert(abi.encodeWithSelector(Token.TooMuchAmountToBuy.selector, tokens(2), tokens(1)));
        token.buy{value: 1 ether}(tokens(2));
    }

    // Buy small amount

    function test_Buy1Token() public {
        token.buy{value: 1 ether}(tokens(1));
        assertFirstBuy(address(this), tokens(1));
    }

    function test_Buy100Tokens() public {
        token.buy{value: 10_000 ether}(tokens(100));
        assertFirstBuy(address(this), tokens(100));
    }

    // Buy huge amount

    function test_BuyHugeAmount() public {
        uint256 ethAmount = 100_000_000_000_000_000_000 ether;
        uint256 buyAmount = tokens(10_000_000_000);
        vm.deal(address(this), ethAmount);

        token.buy{value: ethAmount}(buyAmount);
        assertFirstBuy(address(this), buyAmount);
    }

    function test_BuyEmitEvent() public {
        vm.skip(true);
        // TODO
    }

    // Helpers

    function tokens(uint256 amount) internal view returns (uint256) {
        return amount * 10 ** decimals;
    }

    function assertFirstBuy(address account, uint256 buyAmount) internal {
        assertEq(token.totalSupply(), buyAmount);
        assertEq(token.balanceOf(account), buyAmount);
    }
}
