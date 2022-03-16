pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./wallet.sol";

contract Dex is Wallet {

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
    }

    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public{
        if(side == Side.BUY){
            require(balances[msg.sender]["ETH"] >= amount * price, "Balance too low");
        } //buy LINK using ETH
        else if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Balance too low");
        } //sell LINK back to ETH

        Order[] storage orders = orderBook[ticker][uint(side)]; //this is to store the orderBook mapping to orders array
        orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)); //each new Order will be stored to orders array. filled is 0 here since we don't care for limit order, only for market (check below, where filled is only used for market order function)

        //below if-elseif is for bubble sort
        uint i = orders.length > 0 ? orders.length - 1 : 0;

        if(side == Side.BUY){
            while(i > 0){
                if(orders[i - 1].price > orders[i].price) { //basically if the rightmost order is already the most expensive, then it "breaks" or stops. for example if the order[1] is $5 while order [2] is $3, it's already correct that $5 is more expensive than $3 and should be prioritized
                    break;   
                }
                Order memory orderToMove = orders[i - 1]; //these 4 lines basically "sort" the order based on which one is the most expensive (the rightmost should be the highest buy order)
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }
        else if (side == Side.SELL){ //same logic as side BUY but in reverse since this is about sell
            while(i > 0){
                if(orders[i - 1].price < orders[i].price) {
                    break;   
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }
        nextOrderId++;

    }

    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
        if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Insuffient balance");
        }

        uint orderBookSide;
        if (side == Side.BUY) {
            orderBookSide = 1; //orderBookSide = 1 means sell orders, so the buy side is connected directly to sell orders
        }
        else {
            orderBookSide = 0; //this is the opposite, if sell side = will be connected to buy orders (orderBookSide = 0)
        }

        Order[] storage orders = orderBook[ticker][orderBookSide]; //this is to store the orderBook mapping to orders array but from market orders
    
        uint totalFilled = 0; //since market order might take multiple orders to fill, we need to know totalFilled that the market order takes

        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            uint leftToFill = amount - totalFilled; 
            uint availableToFill = orders[i].amount - orders[i].filled;
            uint filled = 0; //filled order
            
            if (availableToFill > leftToFill) {
                filled = leftToFill;
            } else {
                filled = availableToFill;
            }

            totalFilled += filled;
            orders[i].filled += filled;
            uint cost = filled * orders[i].price;

            if (side == Side.BUY) {
                //verify the buyer has enough ETH
                require(balances[msg.sender]["ETH"] >= cost);
                //msg.sender is the buyer
                balances[msg.sender][ticker] += filled;
                balances[msg.sender]["ETH"] -= cost;

                balances[orders[i].trader][ticker] -= filled;
                balances[orders[i].trader]["ETH"] += cost;
            }   else if (side == Side.SELL) {
                //msg.sender is the seller
                balances[msg.sender][ticker] -= filled;
                balances[msg.sender]["ETH"] += cost;

                balances[orders[i].trader][ticker] += filled;
                balances[orders[i].trader]["ETH"] -= cost;
            }

        }

        //Loop through the orderbook and remove 100% filled orders
        while(orders.length > 0 && orders[0].filled == orders[0].amount) {

            for(uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
        //the while loop above basically removes all the orderbooks that are all filled by the market orders
        //for example, if there are 2 orders that have the price of 1 ETH per token, and market order sweep out these 2 orders at the price of 1 ETH, the while loop will "delete" these 2 orders with the pop function and move up the next orders (with more expensive price) to the top of the orderbook. the while loop stops when there is no more order that get sweeped at once at the same price
    }



}