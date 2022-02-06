import pytest
from brownie import DefiToken, accounts
from web3 import Web3


@pytest.fixture(scope="module")
def defi_token():
    account = accounts[0]
    defi_token = DefiToken.deploy({"from": account})
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
def test_deployer_balance(defi_token):
    assert defi_token.balanceOf(accounts[0]) == Web3.toWei(1_000_000, "ether")
