// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fault is Ownable {
    ERC20 public token;

    constructor (address tokenAddress) {
        token = ERC20(tokenAddress);
    }

    // Withdraw Yak from contract
    function withdraw(address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (amount <= balance){
            token.transferFrom(address(this), to, amount);
        } else {
            token.transferFrom(address(this), to, balance);
        }
    }
}
