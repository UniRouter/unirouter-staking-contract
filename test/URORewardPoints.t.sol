// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/URORewardPoints.sol";

contract MockERC20 is IERC20 {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public allowanceAmount;

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(balances[sender] >= amount, "Insufficient balance");
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowanceAmount[spender] = amount;
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowanceAmount[spender];
    }

    // For testing purposes, allow directly setting balances
    function setBalance(address account, uint256 amount) external {
        balances[account] = amount;
    }
}

contract URORewardPointsTest is Test {
    URORewardPoints public uroRewardPoints;
    MockERC20 public token;

    function setUp() public {
        token = new MockERC20();
        uroRewardPoints = new URORewardPoints(address(token));
        token.approve(address(uroRewardPoints), 1000);
    }

    function testStake() public {
        address user = address(0xBEEF);
        token.setBalance(user, 100);

        vm.startPrank(user);
        uroRewardPoints.stake(50);
        vm.stopPrank();

        assertEq(uroRewardPoints.getTotalStaked(user), 50);
        assertEq(token.balances(user), 50);

        vm.startPrank(user);
        vm.expectRevert("Insufficient balance");
        uroRewardPoints.stake(200);
        vm.stopPrank();
    }

    function testUnstake() public {
        address user = address(0xBEEF);
        token.setBalance(user, 100);

        vm.startPrank(user);
        uroRewardPoints.stake(100);
        uroRewardPoints.unstake(50);
        vm.stopPrank();

        assertEq(uroRewardPoints.getTotalStaked(user), 50);
        assertEq(token.balances(user), 50);

        vm.startPrank(user);
        vm.expectRevert("Insufficient staked amount");
        uroRewardPoints.unstake(200);
        vm.stopPrank();
    }

    function testCalculatePoints() public {
        address user = address(0xBEEF);
        token.setBalance(user, 100);

        vm.startPrank(user);
        vm.warp(0);
        uroRewardPoints.stake(50);

        vm.warp(100);
        uroRewardPoints.stake(30);

        vm.warp(200);
        uroRewardPoints.unstake(20);

        vm.warp(300);
        vm.stopPrank();

        uint256 points = uroRewardPoints.calculatePoints(user);
        uint256 expectedPoints = 50*300 + 30*200 - 20*100;
        assertEq(points, expectedPoints);
    }
}
