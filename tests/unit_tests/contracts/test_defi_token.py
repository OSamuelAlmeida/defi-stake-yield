import pytest
from brownie import DefiToken, reverts, test
from web3 import Web3


@pytest.fixture
def defi_token(deployer_account):
    defi_token = DefiToken.deploy({"from": deployer_account})
    yield defi_token


@pytest.mark.unit
def test_name(defi_token):
    assert defi_token.name() == "DefiToken"


@pytest.mark.unit
def test_symbol(defi_token):
    assert defi_token.symbol() == "DEFI"


@pytest.mark.unit
def test_decimals(defi_token):
    assert defi_token.decimals() == 18


@pytest.mark.unit
def test_total_supply(defi_token):
    assert defi_token.totalSupply() == Web3.toWei(1_000_000, "ether")


@pytest.mark.unit
def test_deployer_balance(defi_token, deployer_account):
    assert defi_token.balanceOf(deployer_account) == Web3.toWei(1_000_000, "ether")


@pytest.mark.unit
@pytest.mark.hypothesis
def test_can_transfer(defi_token, deployer_account):
    @test.given(
        account_address=test.strategy("address", exclude=deployer_account),
        amount=test.strategy(
            "uint256", min_value=1, max_value=Web3.toWei(1_000_000, "ether")
        ),
    )
    def inner_test(account_address, amount):
        defi_token.transfer(account_address, amount, {"from": deployer_account})
        total_supply = defi_token.totalSupply()
        assert defi_token.balanceOf(deployer_account) == total_supply - amount
        assert defi_token.balanceOf(account_address) == amount

    inner_test()


@pytest.mark.unit
@pytest.mark.hypothesis
def test_invalid_transfer_fail(defi_token, deployer_account):
    @test.given(
        account_address=test.strategy("address", exclude=deployer_account),
        amount=test.strategy("uint256", min_value=Web3.toWei(1_000_000, "ether") + 1),
    )
    def inner_test(account_address, amount):
        with reverts():
            defi_token.transfer(account_address, amount, {"from": deployer_account})

    inner_test()
