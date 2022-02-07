import pytest
from brownie import TokenFarm, accounts, reverts, test
from .test_defi_token import defi_token


# TokenFarm.constructor and initialzation


@pytest.fixture
def token_farm(defi_token, deployer_account):
    token_farm = TokenFarm.deploy(defi_token.address, {"from": deployer_account})
    yield token_farm


@pytest.mark.unit
def test_owned_by_deployer(token_farm, deployer_account):
    assert token_farm.owner() == deployer_account


@pytest.mark.unit
def test_IERC20_token_is_defi_token(token_farm, defi_token):
    assert token_farm.defiToken() == defi_token.address


# TokenFarm.insertAllowedToken


@pytest.mark.unit
@pytest.mark.hypothesis
def test_insert_allowed_tokens_non_owner_call_fails(token_farm, deployer_account):
    @test.given(
        account=test.strategy("address", exclude=deployer_account),
        token_address=test.strategy("address"),
        token_reward=test.strategy("uint256"),
    )
    def inner_test(account, token_address, token_reward):
        with reverts("Ownable: caller is not the owner"):
            token_farm.insertAllowedToken(
                token_address, token_reward, {"from": account}
            )

    inner_test()


@pytest.mark.unit
@pytest.mark.hypothesis
def test_insert_allowed_tokens_owner_call_succeeds(token_farm, deployer_account):
    @test.given(
        token_address=test.strategy("address"), token_reward=test.strategy("uint256")
    )
    def inner_test(token_address, token_reward):
        tx = token_farm.insertAllowedToken(
            token_address, token_reward, {"from": deployer_account}
        )
        index = tx.return_value
        assert index == 0

    inner_test()


@pytest.mark.unit
@pytest.mark.hypothesis
def test_insert_already_allowed_token_fails(token_farm, deployer_account):
    @test.given(
        token_address=test.strategy("address"), token_reward=test.strategy("uint256")
    )
    def inner_test(token_address, token_reward):
        token_farm.insertAllowedToken(
            token_address, token_reward, {"from": deployer_account}
        )
        with reverts("token already allowed"):
            token_farm.insertAllowedToken(
                token_address, token_reward, {"from": deployer_account}
            )

    inner_test()


# TokenFarm.isTokenAllowed


@pytest.mark.unit
@pytest.mark.hypothesis
def test_inserted_token_is_allowed(token_farm, deployer_account):
    @test.given(
        token_address=test.strategy("address"), token_reward=test.strategy("uint256")
    )
    def inner_test(token_address, token_reward):
        token_farm.insertAllowedToken(
            token_address, token_reward, {"from": deployer_account}
        )
        assert token_farm.isTokenAllowed(token_address) is True

    inner_test()


@pytest.mark.unit
@pytest.mark.hypothesis
def test_empty_allowed_tokens_no_token_is_allowed(token_farm):
    @test.given(
        token_address=test.strategy("address"),
    )
    def inner_test(token_address):
        assert token_farm.isTokenAllowed(token_address) is False

    inner_test()


@pytest.mark.unit
@pytest.mark.hypothesis
def test_non_inserted_token_is_not_allowed(token_farm, deployer_account):
    @test.given(
        token_address=test.strategy("address", exclude=deployer_account),
        token_reward=test.strategy("uint256"),
    )
    def inner_test(token_address, token_reward):
        token_farm.insertAllowedToken(
            accounts[0], token_reward, {"from": deployer_account}
        )
        assert token_farm.isTokenAllowed(token_address) is False

    inner_test()


# TokenFarm.getStakingBalanceAmount


@pytest.mark.unit
@pytest.mark.hypothesis
def test_staker_starts_with_no_staking_balance_amount(token_farm):
    @test.given(
        token_address=test.strategy("address"), staker_address=test.strategy("address")
    )
    def inner_test(token_address, staker_address):
        assert token_farm.getStakingBalanceAmount(token_address, staker_address) == 0

    inner_test()


# TODO: Test has balance when token is staked
# TODO: Test token2 has no balance when token1 is staked
# TODO: Test token has no balance when unstaked


# TokenFarm.getStakingBalanceTimestamp


@pytest.mark.unit
@pytest.mark.hypothesis
def test_staker_starts_with_no_staking_balance_timestamp(token_farm):
    @test.given(
        token_address=test.strategy("address"), staker_address=test.strategy("address")
    )
    def inner_test(token_address, staker_address):
        assert token_farm.getStakingBalanceTimestamp(token_address, staker_address) == 0

    inner_test()


# TODO: Test has timestamp when token is staked
# TODO: Test token2 has no timestamp when token1 is staked
# TODO: Test token has no timestamp when unstaked


# TokenFarm.isStaking


@pytest.mark.unit
@pytest.mark.hypothesis
def test_staker_starts_not_staking(token_farm):
    @test.given(staker_address=test.strategy("address"))
    def inner_test(staker_address):
        assert token_farm.isStaking(staker_address) is False

    inner_test()


# TODO: Test is staking when token is staked
# TODO: Test is staking when token1 is unstaked but has token2 staked
# TODO: Test is not staking when token is unstaked
# TODO: Test is not staking when token1 and token2 is unstaked


# TokenFarm.stakeToken


@pytest.mark.unit
@pytest.mark.hypothesis
def test_stake_tokens_fail_zero_amount(token_farm, deployer_account):
    @test.given(token_address=test.strategy("address"))
    def inner_test(token_address):
        with reverts("amount > 0"):
            token_farm.stakeToken(
                token_address,
                0,
                {"from": deployer_account},
            )

    inner_test()


@pytest.mark.unit
@pytest.mark.hypothesis
def test_stake_tokens_fail_disallowed_token(token_farm, deployer_account):
    @test.given(
        token_address=test.strategy("address"),
        amount=test.strategy("uint256", min_value=1),
    )
    def inner_test(token_address, amount):
        with reverts("token not allowed"):
            token_farm.stakeToken(
                token_address,
                amount,
                {"from": deployer_account},
            )

    inner_test()


# TODO: Test valid token is staked
# TODO: Test already staked token fails


# TODO: TokenFarm.calculateRewardsForStaker


# TODO: TokenFarm.unstakeToken
