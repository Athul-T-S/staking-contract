StakingContract.sol
--------------------------------
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract StakingContract {

    IERC20 public stakingToken; // The ERC20 token to stake
    uint256 public rewardRate; // Reward rate per second (fixed)
    
    struct Stake {
        uint256 amount; // Amount of tokens staked
        uint256 timestamp; // Time when the tokens were staked
        uint256 rewards; // Accrued rewards
    }
    
    mapping(address => Stake) public stakes;

    constructor(IERC20 _stakingToken, uint256 _rewardRate) {
        stakingToken = _stakingToken;
        rewardRate = _rewardRate; // Reward rate per second
    }

    // Deposit tokens into the staking contract
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        
        // Transfer tokens from the user to this contract
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // If the user already has a stake, calculate and claim rewards before adding new deposit
        if (stakes[msg.sender].amount > 0) {
            uint256 reward = calculateReward(msg.sender);
            stakes[msg.sender].rewards += reward;
        }

        // Update the user's stake
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].timestamp = block.timestamp;
    }

    // Withdraw staked tokens along with earned rewards
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakes[msg.sender].amount >= _amount, "Insufficient staked balance");
        
        // Calculate the rewards for the user
        uint256 reward = calculateReward(msg.sender);
        stakes[msg.sender].rewards += reward;

        // Reduce the user's stake amount
        stakes[msg.sender].amount -= _amount;

        // Transfer the staked tokens and rewards back to the user
        require(stakingToken.transfer(msg.sender, _amount), "Token transfer failed");
        require(stakingToken.transfer(msg.sender, stakes[msg.sender].rewards), "Reward transfer failed");

        // Reset rewards after withdrawal
        stakes[msg.sender].rewards = 0;
        stakes[msg.sender].timestamp = block.timestamp; // Reset the timestamp after withdrawal
    }

    // Calculate rewards based on the time the tokens have been staked
    function calculateReward(address _user) public view returns (uint256) {
        Stake storage stake = stakes[_user];
        if (stake.amount == 0) {
            return 0;
        }

        uint256 timeStaked = block.timestamp - stake.timestamp;
        uint256 reward = stake.amount * rewardRate * timeStaked / 1e18; // Accrue rewards over time
        return reward;
    }

    // View function to check the current balance of staked tokens for a user
    function stakedBalance(address _user) external view returns (uint256) {
        return stakes[_user].amount;
    }

    // View function to check the current rewards for a user
    function pendingRewards(address _user) external view returns (uint256) {
        return calculateReward(_user) + stakes[_user].rewards;
    }
}