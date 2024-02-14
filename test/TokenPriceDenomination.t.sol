// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenPriceDEnominationTest is Test {
    Token public token;
    address owner = address(1);
    uint256 decimals;

    function setUp() public {
        token = new Token(owner, "Curve Token", "TKN", 0, 5_000);
    }

    // Denomination

    function test_EthToToken() public {
        assertEq(token.ethToToken(1 ether), tokens(1));
    }

    function test_tokenToEth() public {
        assertEq(token.tokenToEth(tokens(1)), tokens(1));
    }

    // Helpers

    function tokens(uint256 amount) internal view returns (uint256) {
        return amount * 10 ** token.decimals();
    }
}
