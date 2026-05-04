// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingPlatform is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Pool {
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 totalStaked;
        uint256 accRewardPerShare;
        uint256 lockDuration;
        bool isActive;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lockUntil;
        uint256 totalRewardsClaimed;
    }

    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => UserInfo)) public users;
    uint256 public poolCount;

    event PoolCreated(uint256 indexed poolId, address stakingToken, address rewardToken, uint256 rewardRate);
    event Staked(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 indexed poolId, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function createPool(address _stakingToken, address _rewardToken, uint256 _rewardRate, uint256 _lockDuration) external onlyOwner returns (uint256) {
        uint256 poolId = poolCount++;
        pools[poolId] = Pool(IERC20(_stakingToken), IERC20(_rewardToken), _rewardRate, block.timestamp, 0, 0, _lockDuration, true);
        emit PoolCreated(poolId, _stakingToken, _rewardToken, _rewardRate);
        return poolId;
    }

    function updatePool(uint256 _poolId) public {
        Pool storage pool = pools[_poolId];
        if (block.timestamp <= pool.lastUpdateTime) return;
        if (pool.totalStaked == 0) { pool.lastUpdateTime = block.timestamp; return; }
        uint256 elapsed = block.timestamp - pool.lastUpdateTime;
        uint256 reward = elapsed * pool.rewardRate;
        pool.accRewardPerShare += (reward * 1e18) / pool.totalStaked;
        pool.lastUpdateTime = block.timestamp;
    }

    function stake(uint256 _poolId, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be > 0");
        Pool storage pool = pools[_poolId];
        require(pool.isActive, "Pool not active");
        updatePool(_poolId);
        UserInfo storage user = users[_poolId][msg.sender];
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accRewardPerShare) / 1e18 - user.rewardDebt;
            if (pending > 0) pool.rewardToken.safeTransfer(msg.sender, pending);
        }
        pool.stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        user.amount += _amount;
        user.lockUntil = block.timestamp + pool.lockDuration;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e18;
        pool.totalStaked += _amount;
        emit Staked(msg.sender, _poolId, _amount);
    }

    function withdraw(uint256 _poolId, uint256 _amount) external nonReentrant {
        UserInfo storage user = users[_poolId][msg.sender];
        require(user.amount >= _amount, "Insufficient staked");
        require(block.timestamp >= user.lockUntil, "Still locked");
        Pool storage pool = pools[_poolId];
        updatePool(_poolId);
        uint256 pending = (user.amount * pool.accRewardPerShare) / 1e18 - user.rewardDebt;
        if (pending > 0) { pool.rewardToken.safeTransfer(msg.sender, pending); user.totalRewardsClaimed += pending; }
        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e18;
        pool.totalStaked -= _amount;
        pool.stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _poolId, _amount);
    }

    function claimReward(uint256 _poolId) external nonReentrant {
        Pool storage pool = pools[_poolId];
        UserInfo storage user = users[_poolId][msg.sender];
        updatePool(_poolId);
        uint256 pending = (user.amount * pool.accRewardPerShare) / 1e18 - user.rewardDebt;
        require(pending > 0, "No rewards");
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e18;
        user.totalRewardsClaimed += pending;
        pool.rewardToken.safeTransfer(msg.sender, pending);
        emit RewardClaimed(msg.sender, _poolId, pending);
    }

    function pendingReward(uint256 _poolId, address _user) external view returns (uint256) {
        Pool storage pool = pools[_poolId];
        UserInfo storage user = users[_poolId][_user];
        uint256 accReward = pool.accRewardPerShare;
        if (block.timestamp > pool.lastUpdateTime && pool.totalStaked > 0) {
            uint256 elapsed = block.timestamp - pool.lastUpdateTime;
            accReward += (elapsed * pool.rewardRate * 1e18) / pool.totalStaked;
        }
        return (user.amount * accReward) / 1e18 - user.rewardDebt;
    }

    function emergencyWithdraw(uint256 _poolId) external nonReentrant {
        UserInfo storage user = users[_poolId][msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, "Nothing to withdraw");
        user.amount = 0; user.rewardDebt = 0;
        pools[_poolId].totalStaked -= amount;
        pools[_poolId].stakingToken.safeTransfer(msg.sender, amount);
    }
}