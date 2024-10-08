// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedBetting} from "../src/Betting.sol";

contract BetTest is Test {
    DecentralizedBetting public bet;
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function setUp() public {
        vm.startPrank(owner);
        bet = new  DecentralizedBetting();
        vm.stopPrank();
    }

    function test_e2e() public {
        vm.startPrank(owner);
        bet.setQuestion("who will win", block.timestamp + 10 days);
        string[] memory arr = new string[](2);
        arr[0] = "1";
        arr[1] = "2";
        bet.setOptions(1, arr);
        bet.setAnswer(1, 0);


        bet.setQuestion("who will win 2", block.timestamp + 10 days);
        string[] memory arr2 = new string[](2);
        arr2[0] = "1";
        arr2[1] = "2";
        bet.setOptions(2, arr);
        bet.setAnswer(2, 0);


        vm.stopPrank();


        vm.startPrank(user1);
        vm.deal(user1, 0.2 ether);
        bet.placeBet{value: 0.1 ether}(1, 1);
        bet.placeBet{value: 0.1 ether}(2, 1);


        vm.stopPrank();

        vm.startPrank(user2);
        vm.deal(user2, 0.2 ether);
        bet.placeBet{value: 0.1 ether}(1, 1);
        bet.placeBet{value: 0.1 ether}(2, 1);
        vm.stopPrank();

        vm.startPrank(user3);
        vm.deal(user3, 0.2 ether);
        bet.placeBet{value: 0.1 ether}(1, 0);
         bet.placeBet{value: 0.1 ether}(2, 0);
        vm.stopPrank();

        vm.warp(block.timestamp + 11 days);

        vm.startPrank(owner);
        bet.runBet(1);
        bet.runBet(2);
        vm.stopPrank();


        vm.startPrank(user3);
        console.log(user3.balance);
        bet.withdrawWin(1);
         bet.withdrawWin(2);
        console.log(user3.balance);
        vm.stopPrank();

        bet.getQuestions();
        bet.getOptions(1);

        bet.getBalance(user3);
    }

    
}
