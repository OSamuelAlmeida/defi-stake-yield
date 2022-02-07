// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ERC-20 token staking and rewards contract
/// @author Samuel Almeida - samuel@bravion.dev
/// @notice This contract stakes tokens and rewards stakers with a custom token based on a fixed daily reward factor.
/// @dev This contract allows the staking of ERC-20 tokens
/// @dev and rewards stakers with a custom ERC-20 token based on a fixed daily reward factor defined by the owner.
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
        mapping(address => TokenStake) stakingBalance;
        uint256 index;
    }
    mapping(address => Staker) private stakers;
    address[] private stakersAddresses;

    IERC20 public defiToken;

    /// @dev Constructor for defining the ERC-20 reward token
    /// @param _defiTokenAddress Address of the ERC-20 token to be used as a reward token
    constructor(address _defiTokenAddress) public {
        defiToken = IERC20(_defiTokenAddress);
    }

    /// @notice Allows a user to stake a token amount
    /// @notice The user can only stake a token once
    /// @notice The user can only stake allowed tokens
    /// @notice To change the amount staked, the user must unstake the previous amount and stake the new amount
    /// @param _token Address of the ERC-20 token to be staked
    /// @param _amount Amount of the ERC-20 token to be staked
    /// @return amount The amount staked
    /// @return timestamp The timestamp of the staking
    function stakeToken(address _token, uint256 _amount)
        external
        returns (uint256 amount, uint256 timestamp)
    {
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

        return (amount, timestamp);
    }

    /// @notice Allows a user to unstake a token
    /// @notice The whole amount staked is returned to the user
    /// @notice The user also receives their reward when unstaking
    /// @param _token The address of the ERC-20 token
    /// @return unstakedAmount The amount unstaked
    /// @return reward The reward received
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

    /// @dev Allows the owner to add a token to the list of allowed tokens
    /// @dev A user can only stake tokens in the allowedTokens list
    /// @param _token The address of the ERC-20 token
    /// @param _dailyRewardFactor The daily reward factor for the token
    /// @return index The index of the token in the allowedTokens list
    function insertAllowedToken(address _token, uint256 _dailyRewardFactor)
        public
        onlyOwner
        returns (uint256 index)
    {
        require(!this.isTokenAllowed(_token), "token already allowed");
        allowedTokens[_token].dailyRewardFactor = _dailyRewardFactor;
        allowedTokens[_token].index = allowedTokensAddresses.length;
        allowedTokensAddresses.push(_token);
        return allowedTokensAddresses.length - 1;
    }

    /// @notice Checks if a given token is allowed
    /// @param _token The address of the ERC-20 token
    /// @return tokenAllowed True if the token is allowed
    function isTokenAllowed(address _token)
        public
        view
        returns (bool tokenAllowed)
    {
        if (allowedTokensAddresses.length == 0) return false;
        return (allowedTokensAddresses[allowedTokens[_token].index] == _token);
    }

    /// @notice Returns the amount of tokens staked by a given user
    /// @param _token The address of the ERC-20 token
    /// @param _staker The address of the staker
    /// @return amount The amount of tokens staked
    function getStakingBalanceAmount(address _token, address _staker)
        public
        view
        returns (uint256 amount)
    {
        return stakers[_staker].stakingBalance[_token].amount;
    }

    /// @notice Returns the timestamp of the staking of a given token by a given user
    /// @param _token The address of the ERC-20 token
    /// @param _staker The address of the staker
    /// @return timestamp The timestamp of the staking
    function getStakingBalanceTimestamp(address _token, address _staker)
        public
        view
        returns (uint256 timestamp)
    {
        return stakers[_staker].stakingBalance[_token].timestamp;
    }

    /// @notice Returns whether a given user is staking any token
    /// @param _staker The address of the staker
    /// @return staking True if the user is staking any token
    function isStaking(address _staker) public view returns (bool staking) {
        if (stakersAddresses.length == 0) return false;
        return (stakersAddresses[stakers[_staker].index] == _staker);
    }

    /// @notice Returns whether a given user is staking a given token
    /// @param _token The address of the ERC-20 token
    /// @param _staker The address of the staker
    /// @return stakingToken True if the user is staking the token
    function isStakingToken(address _token, address _staker)
        public
        view
        returns (bool stakingToken)
    {
        if (!this.isStaking(_staker)) return false;
        return (stakers[_staker].stakingBalance[_token].amount > 0);
    }

    /// @notice Calculates the amount of reward tokens a given user will receive when unstaking a given token
    /// @param _token The address of the ERC-20 token
    /// @param _staker The address of the staker
    /// @return reward The amount of reward tokens
    function calculateRewardsForStaker(address _token, address _staker)
        public
        view
        returns (uint256 reward)
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
        reward = stakingBalanceAmount * currentRewardFactor;

        return reward;
    }
}
