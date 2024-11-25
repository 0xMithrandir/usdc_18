// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { USDC18 } from "../src/USDC18.sol";
import { IERC20 } from "forge-std/src/interfaces/IERC20.sol";
import { console2 } from "forge-std/src/console2.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Script to deploy USDC18 contract
contract Deploy is BaseScript {
    address public constant OPTIMISM_USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address public constant ETHEREUM_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() public broadcast returns (USDC18 usdc18) {
        usdc18 = new USDC18(OPTIMISM_USDC);
        console2.log("USDC18 deployed at", address(usdc18));

        // Test deposit 0.01 USDC
        IERC20(OPTIMISM_USDC).approve(address(usdc18), 0.1e5);
        usdc18.deposit(0.1e5);
        console2.log("Deposited 0.01 USDC");
        console2.log("Balance of USDC18", usdc18.balanceOf(address(this)));

        // Test withdraw all USDC18
        usdc18.withdraw(0.1e5 * 1e12);
        console2.log("Withdrew all USDC18");
        console2.log("Balance of USDC", IERC20(OPTIMISM_USDC).balanceOf(address(this)));
    }
}
