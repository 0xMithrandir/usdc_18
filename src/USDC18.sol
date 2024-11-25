// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract USDC18 is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable USDC;
    uint256 public immutable DECIMAL_CONVERTER;

    event Deposit(address indexed user, uint256 usdcAmount, uint256 usdc18Amount);
    event Withdraw(address indexed user, uint256 usdc18Amount, uint256 usdcAmount);

    constructor(address usdcAddress) ERC20("USDC_18", "USDC18") {
        USDC = IERC20Metadata(usdcAddress);
        uint8 usdcDecimals = USDC.decimals();
        require(usdcDecimals <= 18, "USDC decimals must be <= 18");
        DECIMAL_CONVERTER = 10 ** (18 - usdcDecimals);
    }

    /**
     * @dev Deposits USDC and mints USDC18 tokens
     * @param amount Amount of USDC to deposit (in USDC's decimals)
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer USDC from user to this contract
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        // Convert amount to 18 decimals and mint USDC18
        uint256 amount18 = amount * DECIMAL_CONVERTER;
        _mint(msg.sender, amount18);

        emit Deposit(msg.sender, amount, amount18);
    }

    /**
     * @dev Withdraws USDC by burning USDC18 tokens
     * @param amount18 Amount of USDC18 to burn (in 18 decimals)
     */
    function withdraw(uint256 amount18) external nonReentrant {
        require(amount18 > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount18, "Insufficient balance");

        // Convert amount back to USDC decimals
        uint256 usdcAmount = amount18 / DECIMAL_CONVERTER;
        require(usdcAmount > 0, "Withdraw amount too small");

        // Burn USDC18 tokens
        _burn(msg.sender, amount18);

        // Transfer USDC back to user
        USDC.safeTransfer(msg.sender, usdcAmount);

        emit Withdraw(msg.sender, amount18, usdcAmount);
    }

    /**
     * @dev Returns the number of decimals used for USDC18
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the amount of USDC held by this contract
     */
    function getUSDCBalance() external view returns (uint256) {
        return USDC.balanceOf(address(this));
    }
}
