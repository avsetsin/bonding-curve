// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract BondingCurveTest is Test {
    BondingCurve public bondingCurve;

    function setUp() public {
        bondingCurve = new BondingCurve();
        bondingCurve.setNumber(0);
    }

    function test_Increment() public {
        bondingCurve.increment();
        assertEq(bondingCurve.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        bondingCurve.setNumber(x);
        assertEq(bondingCurve.number(), x);
    }
}
