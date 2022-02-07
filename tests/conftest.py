import pytest
from brownie import accounts, network

network.connect("development")


@pytest.fixture
def deployer_account():
    yield accounts[0]
