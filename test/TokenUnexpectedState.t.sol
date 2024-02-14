// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Token} from "../src/Token.sol";

contract TokenUnexpectedStateTest is Test {
    Token public token;
    address owner = address(1);
    address account = address(2);

    function setUp() public {
        token = new Token(owner, "Curve Token", "TKN", 0, 5_000);
    }

    function test_UnexpectedContractBalance() public {
        vm.startPrank(account);

        vm.deal(account, 2 ether);
        token.buy{value: 2 ether}(0);

        vm.deal(address(token), 1 ether);
        vm.expectRevert(stdError.assertionError);
        token.sell(1);

        vm.stopPrank();
    }
}
