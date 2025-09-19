// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EscrowPayment} from "../src/EscrowPayment.sol";

contract CounterTest is Test {
    EscrowPayment public escrowPayment;

    function setUp() public {
        escrowPayment = new EscrowPayment();
    }
}
