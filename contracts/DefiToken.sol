// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Token used as rewards for the Defi Stake Yield Dapp
/// @author Samuel Almeida - samuel@bravion.dev
/// @notice This token is used to reward the stakers in the Defi Stake Yield Dapp
/// @dev This is an ERC-20 token implemetentation based on the ERC-20 OpenZeppelin contract
contract DefiToken is ERC20 {
    constructor() ERC20("DefiToken", "DEFI") {
        _mint(msg.sender, 1_000_000 ether);
    }
}
