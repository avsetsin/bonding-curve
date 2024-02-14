// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenSetupTest is Test {
    Token public token;
    address owner = address(1);

    function setUp() public {
        token = new Token(owner, "Curve Token", "TKN", 5 minutes, 10_000);
    }

    function test_Owner() public {
        assertEq(token.owner(), owner);
    }

    function test_TokenName() public {
        assertEq(token.name(), "Curve Token");
    }

    function test_TokenSymbol() public {
        assertEq(token.symbol(), "TKN");
    }

    function test_InitialSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    function test_PriceRatio() public {
        assertEq(token.PRICE_RATIO(), 10_000);
    }

    function test_CoolDownTime() public {
        assertEq(token.coolDownTime(), 5 minutes);
    }
}
