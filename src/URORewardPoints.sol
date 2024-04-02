// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface IERC20 {
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//     function transfer(address recipient, uint256 amount) external returns (bool);
//     function approve(address spender, uint256 amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint256);
// }

contract URORewardPoints {
    IERC20 public token;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    struct Unstake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake[]) public stakes;
    mapping(address => Unstake[]) public unstakes;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);

    constructor(address _tokenAddress) {
        if (_tokenAddress != address(0)) {
            token = IERC20(_tokenAddress);
        }
    }

    function stake(uint256 amount) external payable {
        require(amount > 0, "Cannot stake 0");
        if (address(token) == address(0)) {
            // Staking native token (e.g., ETH)
            require(msg.value == amount, "Incorrect value sent");
        } else {
            // Staking ERC20 token
            require(msg.value == 0, "Value should be 0 for ERC20");
            require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
            require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        }

        stakes[msg.sender].push(Stake(amount, block.timestamp));
        emit Staked(msg.sender, amount, block.timestamp);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Cannot unstake 0");
        uint256 totalStaked = getTotalStaked(msg.sender);
        require(totalStaked >= amount, "Insufficient staked amount");

        unstakes[msg.sender].push(Unstake(amount, block.timestamp));

        if (address(token) == address(0)) {
            // Unstaking native token
            (bool sent,) = msg.sender.call{value: amount}("");

            require(sent, "Failed to send native token");
        } else {
            // Unstaking ERC20 token
            require(token.transfer(msg.sender, amount), "Token transfer failed");
        }
        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    function getTotalStaked(address user) public view returns (uint256 total) {
        for (uint256 i = 0; i < stakes[user].length; i++) {
            total += stakes[user][i].amount;
        }
        for (uint256 i = 0; i < unstakes[user].length; i++) {
            total -= unstakes[user][i].amount;
        }
    }

    function calculatePoints(address user) public view returns (uint256 points) {
        for (uint256 i = 0; i < stakes[user].length; i++) {
            Stake memory stakeRecord = stakes[user][i];
            uint256 duration = block.timestamp - stakeRecord.timestamp;
            points += stakeRecord.amount * duration;
        }
        for (uint256 i = 0; i < unstakes[user].length; i++) {
            Unstake memory unstakeRecord = unstakes[user][i];
            uint256 duration = block.timestamp - unstakeRecord.timestamp;
            points -= unstakeRecord.amount * duration;
        }
    }
}
