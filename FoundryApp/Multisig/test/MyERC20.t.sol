// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MyERC20} from "src/MyERC20.sol";

contract MyERC20Test is Test {
    MyERC20 myerc20;

    address owner = makeAddr("owner");
    address spender = makeAddr("spender");

    function setUp() public {
        vm.prank(owner);
        myerc20 = new MyERC20();
    }

    function testreturnTokenName() public view {
        string memory tokenName = myerc20.name();
        assertEq(tokenName, "BELZIEE");
    }

    function testreturnTokenSymbol() public view {
        string memory tokenSymbol = myerc20.symbol();
        assertEq(tokenSymbol, "BLZ");
    }

    function testreturnTokenDecimal() public view {
        assertEq(myerc20.decimals(), uint8(18));
    }

    function testreturnTokenTotalSupply() public view {
        assertEq(myerc20.totalSupply(), 0);
    }

    function testreturnBalanceOfOwner() public {
        vm.prank(owner);
        assertEq(myerc20.balanceOf(owner), 0);
    }

    function testReturnAllowance() public view {
        assertEq(myerc20.allowance(owner, spender), 0);
    }

    function testSetAllowance() public {
        myerc20.mint(owner, 1000000000000000000000);
        uint allowFee = 10000000000000000000;
        vm.prank(owner);
        myerc20.approve(spender, allowFee);
        assertEq(myerc20.allowance(owner, spender), allowFee);
    }

    function testTransferFrom() public {
        myerc20.mint(owner, 1000000000000000000000);
        uint allowFee = 10000000000000000000;
        vm.prank(owner);
        myerc20.approve(spender, allowFee);
        assertEq(myerc20.allowance(owner, spender), allowFee);
        vm.prank(spender);
        myerc20.transferFrom(owner, spender, allowFee);
        assertEq(myerc20.balanceOf(spender), allowFee);

        // This is the KEY part:
        // transferFrom(owner, recipient, amount)
        // The caller must be the spender.
        // So: msg.sender MUST equal spender
    }

    function testTransferTokens() public {
        myerc20.mint(owner, 1000000000000000000000);
        uint amountToPay = 10000000000000000000;
        vm.prank(owner);
        myerc20.transfer(spender, amountToPay);
        assertEq(myerc20.balanceOf(spender), amountToPay);
    }
}
