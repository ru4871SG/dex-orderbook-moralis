// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {

    struct Token { //token that will be tradeable on the dex
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokenMapping; //to find the token via the ticker
    bytes32[] public tokenList; //array of the token tickers which is the token list

    mapping(address => mapping(bytes32 => uint256)) public balances; //wallet address => token ticker (in bytes32) => the amount of balance

    modifier tokenExist(bytes32 ticker) {
        require(tokenMapping[ticker].tokenAddress != address(0)); //to make sure the token is not an empty token, but actually something that was deployed
        _;
    }

    function addToken(bytes32 ticker, address tokenAddress) onlyOwner external {
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
    
    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external {
        balances[msg.sender][ticker] += amount; 
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount); //sending from the msg.sender to the smart contract
    }


    function withdraw(uint amount, bytes32 ticker) tokenExist(ticker) external {
        require(balances[msg.sender][ticker] >= amount, "Balance is not sufficient");

        balances[msg.sender][ticker] -= amount;
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount); //withdrawing from this smart contract to the msg.sender
    }

    function depositEth() payable external {
        balances[msg.sender][bytes32("ETH")] += msg.value;
    }
    
    function withdrawEth(uint amount) external {
        require(balances[msg.sender][bytes32("ETH")] >= amount,'Insuffient balance'); 
        balances[msg.sender][bytes32("ETH")] -= amount;
        msg.sender.call{value:amount}("");
    }



}

