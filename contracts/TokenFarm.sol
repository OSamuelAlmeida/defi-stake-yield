// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenFarm is Ownable {
    struct StakeableToken {
        uint256 index;
        uint256 dailyRewardFactor;
    }
    mapping(address => StakeableToken) private allowedTokens;
    address[] private allowedTokensAddresses;

    struct TokenStake {
        uint256 amount;
        uint256 timestamp;
    }
    struct Staker {
        // Token address => Amount
        mapping(address => TokenStake) stakingBalance;
        address[] stakingBalanceAddresses;
        uint256 index;
    }
    mapping(address => Staker) private stakers;
    address[] private stakersAddresses;

    IERC20 public defiToken;

    constructor(address _defiTokenAddress) {
        defiToken = IERC20(_defiTokenAddress);
    }

    function insertAllowedToken(address _token, uint256 dailyRewardFactor)
        public
        onlyOwner
        returns (uint256)
    {
        require(!this.isTokenAllowed(_token), "token already allowed");
        allowedTokens[_token].dailyRewardFactor = dailyRewardFactor;
        allowedTokens[_token].index = allowedTokensAddresses.length;
        allowedTokensAddresses.push(_token);
        return allowedTokensAddresses.length - 1;
    }

    function isTokenAllowed(address _token) public view returns (bool) {
        if (allowedTokensAddresses.length == 0) return false;
        return (allowedTokensAddresses[allowedTokens[_token].index] == _token);
    }

    function getStakingBalanceAmount(address _token, address _staker)
        public
        view
        returns (uint256)
    {
        return stakers[_staker].stakingBalance[_token].amount;
    }

    function getStakingBalanceTimestamp(address _token, address _staker)
        public
        view
        returns (uint256)
    {
        return stakers[_staker].stakingBalance[_token].timestamp;
    }

    function isStaking(address _staker) public view returns (bool) {
        if (stakersAddresses.length == 0) return false;
        return (stakersAddresses[stakers[_staker].index] == _staker);
    }

    function isStakingToken(address _token, address _staker)
        public
        view
        returns (bool)
    {
        if (!this.isStaking(_staker)) return false;
        return (stakers[_staker].stakingBalance[_token].amount > 0);
    }

    function stakeToken(address _token, uint256 _amount) external {
        require(_amount > 0, "amount > 0");
        require(this.isTokenAllowed(_token), "token not allowed");
        require(!isStakingToken(_token, msg.sender), "token already staked");

        if (!this.isStaking(msg.sender)) {
            stakers[msg.sender].index = stakersAddresses.length;
            stakersAddresses.push(msg.sender);
        }

        stakers[msg.sender].stakingBalance[_token].amount = _amount;
        stakers[msg.sender].stakingBalance[_token].timestamp = block.timestamp;

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function calculateRewardsForStaker(address _token, address _staker)
        public
        view
        returns (uint256)
    {
        if (!this.isStakingToken(_token, _staker)) {
            return 0;
        }

        uint256 stakingBalanceAmount = stakers[_staker]
            .stakingBalance[_token]
            .amount;
        uint256 stakingBalanceTimestamp = stakers[_staker]
            .stakingBalance[_token]
            .timestamp;
        uint256 daysSinceStaking = (block.timestamp - stakingBalanceTimestamp) /
            1 days;
        uint256 currentRewardFactor = allowedTokens[_token].dailyRewardFactor *
            daysSinceStaking;
        uint256 reward = stakingBalanceAmount * currentRewardFactor;

        return reward;
    }

    function unstakeToken(address _token)
        external
        returns (uint256 unstakedAmount, uint256 reward)
    {
        require(isStakingToken(_token, msg.sender), "not staking");

        unstakedAmount = stakers[msg.sender].stakingBalance[_token].amount;
        reward = this.calculateRewardsForStaker(_token, msg.sender);
        stakers[msg.sender].stakingBalance[_token].amount = 0;

        uint256 totalStakedBalance = 0;
        for (uint256 i = 0; i < allowedTokensAddresses.length; i++) {
            totalStakedBalance += stakers[msg.sender]
                .stakingBalance[allowedTokensAddresses[i]]
                .amount;
        }

        if (totalStakedBalance <= 0) {
            uint256 stakerToRemove = stakers[msg.sender].index;
            address stakerAddressToMove = stakersAddresses[
                stakersAddresses.length - 1
            ];
            stakersAddresses[stakerToRemove] = stakerAddressToMove;
            stakers[stakerAddressToMove].index = stakerToRemove;
            stakersAddresses.pop();
        }

        IERC20(_token).transfer(msg.sender, unstakedAmount);
        defiToken.transfer(msg.sender, reward);

        return (unstakedAmount, reward);
    }
}
