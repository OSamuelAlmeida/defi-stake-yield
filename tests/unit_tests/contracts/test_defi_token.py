import pytest
from brownie import DefiToken, accounts
from web3 import Web3


@pytest.fixture(scope="module")
def defi_token():
    account = accounts[0]
    defi_token = DefiToken.deploy({"from": account})
    yield defi_token


def test_defi_token_name(defi_token):
    assert defi_token.name() == "DefiToken"


def test_defi_token_symbol(defi_token):
    assert defi_token.symbol() == "DEFI"


def test_defi_token_decimals(defi_token):
    assert defi_token.decimals() == 18


def test_defi_token_total_supply(defi_token):
    assert defi_token.totalSupply() == Web3.toWei(1_000_000, "ether")


def test_defi_token_deployer_balance(defi_token):
    assert defi_token.balanceOf(accounts[0]) == Web3.toWei(1_000_000, "ether")
