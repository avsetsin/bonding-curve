// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {CoolDown} from "../src/CoolDown.sol";

contract TokenPriceCoolDownTest is Test {
    Token public token;
    address owner = address(1);
    address account = address(2);

    event CoolDownTimeUpdated(uint256 coolDownTime);
    event CoolDownStarted(address indexed account, uint256 coolDownToTime);

    function setUp() public {
        token = new Token(owner, "Curve Token", "TKN", 1 minutes, 5_000);
        vm.deal(account, 100 ether);
    }

    function test_NoCoolDownForNewAccount() public {
        assertTrue(token.isCoolDownPassed(account));
    }

    function test_CoolDownAfterBuy() public {
        vm.prank(account);
        token.buy{value: 1 ether}(0);
        assertFalse(token.isCoolDownPassed(account));
        assertEq(token.coolDownTimes(account), 1 minutes + block.timestamp);
    }

    // Sell

    function test_SellingIsLockedAfterBuy() public {
        vm.startPrank(account);
        token.buy{value: 1 ether}(0);

        uint256 expectedCoolDownTo = block.timestamp + 1 minutes;
        uint256 secondBeforeCollDown = expectedCoolDownTo - 1 seconds;

        vm.warp(secondBeforeCollDown);
        vm.expectRevert(abi.encodeWithSelector(CoolDown.CoolDownNotPassed.selector, account, expectedCoolDownTo));
        token.sell(1);
        vm.stopPrank();
    }

    function test_SellingIsUnlockedAfterCoolDown() public {
        vm.startPrank(account);
        token.buy{value: 1 ether}(0);
        vm.warp(block.timestamp + 1 minutes);
        token.sell(1);
        vm.stopPrank();
    }

    // Transfer

    function test_TransferingIsLockedAfterBuy() public {
        vm.startPrank(account);
        token.buy{value: 1 ether}(0);

        uint256 expectedCoolDownTo = block.timestamp + 1 minutes;
        uint256 secondBeforeCollDown = expectedCoolDownTo - 1 seconds;

        vm.warp(secondBeforeCollDown);
        vm.expectRevert(abi.encodeWithSelector(CoolDown.CoolDownNotPassed.selector, account, expectedCoolDownTo));
        token.transfer(address(3), 1);
        vm.stopPrank();
    }

    function test_TransferingIsUnlockedAfterCoolDown() public {
        vm.startPrank(account);
        token.buy{value: 1 ether}(0);
        vm.warp(block.timestamp + 1 minutes);
        token.transfer(address(3), 1);
        vm.stopPrank();
    }

    // Update time

    function test_UpdateCoolDownTime() public {
        vm.prank(owner);
        token.updateCoolDownTime(2 minutes);
        assertEq(token.coolDownTime(), 2 minutes);
    }

    function test_UpdateCoolDownTimeByStranger() public {
        vm.prank(account);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, account));
        token.updateCoolDownTime(2 minutes);
    }

    // Events

    function test_CoolDownStartedEvent() public {
        vm.expectEmit(true, true, true, true, address(token));
        emit CoolDownStarted(account, block.timestamp + 1 minutes);

        vm.prank(account);
        token.buy{value: 1 ether}(0);
    }

    function test_CoolDownTimeUpdatedEvent() public {
        vm.expectEmit(true, true, true, true, address(token));
        emit CoolDownTimeUpdated(2 minutes);

        vm.prank(owner);
        token.updateCoolDownTime(2 minutes);
    }
}
