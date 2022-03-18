// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//this is just a mock token where we pretend this is chainlink

contract Link is ERC20 {
    constructor() ERC20("Chainlink", "LINK") public {
        _mint(msg.sender, 1e24); 
    }
}