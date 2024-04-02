// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/URORewardPoints.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract URORewardPointsETHTest is Test {
    URORewardPoints uroRewardPoints;
    address user;

    function setUp() public {
        uroRewardPoints = new URORewardPoints(address(0));
        user = address(0xBEEF);
    }

    function testStakeETH() public {
        vm.startPrank(user);

        uint256 amount = 2 ether;
        vm.deal(user, 3 ether);
        vm.warp(0);
        uroRewardPoints.stake{value: amount}(amount);

        assertEq(uroRewardPoints.getTotalStaked(user), amount, "Staked token should be equal to amount.");
        assertEq(user.balance, 1 ether);

        vm.warp(100);
        assertEq(uroRewardPoints.calculatePoints(user), 100 * 2 * 1e18);
        vm.stopPrank();
    }

    function testUnstakeETH() public {
        vm.startPrank(user);

        uint256 amount = 2 ether;
        vm.deal(user, amount);
        vm.warp(0);
        uroRewardPoints.stake{value: amount}(amount);

        vm.warp(100);
        uroRewardPoints.unstake(amount);

        assertEq(uroRewardPoints.getTotalStaked(user), 0, "Staked token should be empty.");
        assertEq(user.balance, amount);
        assertEq(uroRewardPoints.calculatePoints(user), 100 * 2 * 1e18);
        vm.stopPrank();
    }
}

contract URORewardPointsERC20Test is Test {
    URORewardPoints uroRewardPoints;
    MockERC20 mockERC20;
    address user;

    function setUp() public {
        mockERC20 = new MockERC20("Mock ERC20", "mERC20");
        uroRewardPoints = new URORewardPoints(address(mockERC20));

        user = address(0xBEEF);
        mockERC20.mint(user, 100);
    }

    function testStakeERC20() public {
        vm.startPrank(user);

        vm.warp(0);
        uint256 amount = 10;
        mockERC20.approve(address(uroRewardPoints), amount);
        uroRewardPoints.stake(amount);

        assertEq(uroRewardPoints.getTotalStaked(user), amount, "Staked token should be equal to amount.");
        assertEq(mockERC20.balanceOf(address(user)), 90, "ERC20 token balance should be reduced by staked amount");

        vm.warp(100);
        assertEq(uroRewardPoints.calculatePoints(user), 10 * 100);
        vm.stopPrank();
    }

    function testUnstakeERC20() public {
        vm.startPrank(user);

        vm.warp(0);
        uint256 amount = 10;
        mockERC20.approve(address(uroRewardPoints), amount);
        uroRewardPoints.stake(amount);

        vm.warp(100);
        uroRewardPoints.unstake(9);

        assertEq(uroRewardPoints.getTotalStaked(user), 1, "Staked token should be reduced.");
        assertEq(mockERC20.balanceOf(address(user)), 99, "ERC20 token balance should be reduced by staked amount");
        assertEq(uroRewardPoints.calculatePoints(user), 100 * 10);

        vm.warp(200);
        assertEq(uroRewardPoints.calculatePoints(user), 100 * 10 + 1 * 100);
        vm.stopPrank();
    }
}
