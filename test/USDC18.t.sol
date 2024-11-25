// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import { USDC18 } from "../src/USDC18.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @dev Tests for USDC18 contract which wraps USDC (6 decimals) to 18 decimals
contract USDC18Test is Test {
    USDC18 internal usdc18;
    IERC20 internal usdc;

    // USDC contract on Optimism
    address constant USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

    /// @dev Setup test environment
    function setUp() public virtual {
        // Fork Optimism mainnet at current timestamp
        vm.createSelectFork("optimism");

        // Deploy USDC18
        usdc18 = new USDC18(USDC);
        usdc = IERC20(USDC);
    }

    /// @dev Test initialization parameters
    function test_Initialize() external {
        assertEq(usdc18.name(), "USDC_18");
        assertEq(usdc18.symbol(), "USDC18");
        assertEq(usdc18.decimals(), 18);
        assertEq(address(usdc18.USDC()), USDC);
    }

    /// @dev Test deposit function
    function test_Deposit() external {
        uint256 amount = 1000e6; // 1000 USDC
        deal(USDC, address(this), amount);

        IERC20(USDC).approve(address(usdc18), amount);

        usdc18.deposit(amount);

        // Check balances
        assertEq(IERC20(USDC).balanceOf(address(this)), 0);
        assertEq(IERC20(USDC).balanceOf(address(usdc18)), amount);
        assertEq(usdc18.balanceOf(address(this)), amount * 1e12); // Convert to 18 decimals
    }

    /// @dev Test withdraw function
    function test_Withdraw() external {
        uint256 amount = 1000e6; // 1000 USDC
        deal(USDC, address(this), amount);

        IERC20(USDC).approve(address(usdc18), amount);
        usdc18.deposit(amount);

        usdc18.withdraw(amount * 1e12); // 18 decimals

        // Check balances
        assertEq(IERC20(USDC).balanceOf(address(this)), amount);
        assertEq(IERC20(USDC).balanceOf(address(usdc18)), 0);
        assertEq(usdc18.balanceOf(address(this)), 0);
    }

    /// @dev Fuzz test deposit with random amounts
    function testFuzz_Deposit(uint256 amount) external {
        // Bound amount to reasonable values and avoid overflow
        amount = bound(amount, 1e6, 10_000_000e6); // 1 USDC to 10M USDC

        deal(USDC, address(this), amount);
        IERC20(USDC).approve(address(usdc18), amount);

        usdc18.deposit(amount);

        assertEq(IERC20(USDC).balanceOf(address(this)), 0);
        assertEq(IERC20(USDC).balanceOf(address(usdc18)), amount);
        assertEq(usdc18.balanceOf(address(this)), amount * 1e12);
    }

    /// @dev Fuzz test withdraw with random amounts
    function testFuzz_Withdraw(uint256 amount) external {
        // Bound amount to reasonable values and avoid overflow
        amount = bound(amount, 1e6, 10_000_000e6); // 1 USDC to 10M USDC

        deal(USDC, address(this), amount);
        IERC20(USDC).approve(address(usdc18), amount);
        usdc18.deposit(amount);

        usdc18.withdraw(amount * 1e12);

        assertEq(IERC20(USDC).balanceOf(address(this)), amount);
        assertEq(IERC20(USDC).balanceOf(address(usdc18)), 0);
        assertEq(usdc18.balanceOf(address(this)), 0);
    }

    /// @dev Test deposit reverts with insufficient balance when user has no USDC
    function test_RevertDeposit_InsufficientBalance() external {
        IERC20(USDC).approve(address(usdc18), 1000e6);

        vm.expectRevert();
        usdc18.deposit(1000e6);
    }

    /// @dev Test withdraw reverts with insufficient balance when user has no USDC18
    function test_RevertWithdraw_InsufficientBalance() external {
        vm.expectRevert();
        usdc18.withdraw(1000e18);
    }
}
