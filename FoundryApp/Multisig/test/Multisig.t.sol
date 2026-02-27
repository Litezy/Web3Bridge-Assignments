// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Multisig.sol";

contract MultisigTest is Test {
    Multisig multisigContract;

    address owner1 = makeAddr("owner1");
    address owner2 = makeAddr("owner2");
    address owner3 = makeAddr("owner3");
    address owner4 = makeAddr("owner4");
    address owner5 = makeAddr("owner5");
    address owner6 = makeAddr("owner6");
    address nonOwner = makeAddr("nonOwner");

    function setUp() public {
        // deploy as owner1
        vm.prank(owner1);
        multisigContract = new Multisig();

        // fund all owners with ETH
        deal(owner1, 10 ether);
        deal(owner2, 10 ether);
        deal(owner3, 10 ether);
        deal(owner4, 10 ether);
        deal(owner5, 10 ether);
        deal(owner6, 10 ether);
        deal(nonOwner, 10 ether);
    }

    function test_PopulateFiveOwners() public {
        vm.prank(owner2);
        multisigContract.makeOwner();

        vm.prank(owner3);
        multisigContract.makeOwner();

        vm.prank(owner4);
        multisigContract.makeOwner();

        vm.prank(owner5);
        multisigContract.makeOwner();
    }

    function test_RevertSixthOwner() public {
        vm.prank(owner2);
        multisigContract.makeOwner();

        vm.prank(owner3);
        multisigContract.makeOwner();

        vm.prank(owner4);
        multisigContract.makeOwner();

        vm.prank(owner5);
        multisigContract.makeOwner();
        vm.prank(owner6);
        multisigContract.makeOwner();

        // should fail for owner6
        vm.prank(nonOwner);
        vm.expectRevert("Owners are filled, no room for more");
        multisigContract.makeOwner();
    }

    function test_OnlyOwnersCanDepositEther() public {
        // owner deposits
        vm.prank(owner1);
        multisigContract.depositEther{value: 0.5 ether}();

        // non owner should revert
        vm.prank(nonOwner);
        vm.expectRevert("Only owner can deposit");
        multisigContract.depositEther{value: 0.5 ether}();
    }

    function test_CreateTransactionAndAutoApprove() public {
        uint256 amount = 0.5 ether;

        vm.prank(owner1);
        multisigContract.createATransaction(owner6, amount);

        Multisig.Transaction memory tx = multisigContract.getOneTransaction(1);

        assertEq(tx.to, owner6);
        assertEq(tx.value, amount);
        assertEq(tx.approvals, 1);
    }

    function test_RevertIfNonOwnerCreatesTransaction() public {
        vm.expectRevert("Only owner can create a transaction");
        vm.prank(nonOwner);
        multisigContract.createATransaction(owner1, 100);
    }

    function test_RevertForInvalidTransactionId() public {
        vm.expectRevert("Invalid Transaction Id");
        multisigContract.getOneTransaction(1);
    }

    function test_AllowOwnerToApproveTransaction() public {
        vm.prank(owner1);
        multisigContract.createATransaction(owner2, 100);

        vm.prank(owner2);
        multisigContract.approveTransaction(1);

        Multisig.Transaction memory tx = multisigContract.getOneTransaction(1);
        assertEq(tx.approvals, 2);
    }

    function test_PreventDoubleApproval() public {
        vm.prank(owner1);
        multisigContract.createATransaction(owner2, 100);

        vm.prank(owner2);
        multisigContract.approveTransaction(1);

        vm.expectRevert("You have already approved this transaction");
        vm.prank(owner2);
        multisigContract.approveTransaction(1);
    }

    function test_ExecuteTransactionWhenThresholdReached() public {
        // deposit ether first
        vm.prank(owner1);
        multisigContract.depositEther{value: 1 ether}();

        uint256 amount = 0.5 ether;

        vm.prank(owner1);
        multisigContract.createATransaction(owner3, amount);

        uint256 balanceBefore = owner3.balance;

        // 2nd approval - should NOT execute yet
        vm.prank(owner2);
        multisigContract.approveTransaction(1);

        Multisig.Transaction memory tx = multisigContract.getOneTransaction(1);
        assertEq(tx.executed, false);
        assertEq(owner3.balance, balanceBefore); // balance unchanged

        // 3rd approval - should trigger execution
        vm.prank(owner3);
        multisigContract.approveTransaction(1);

        tx = multisigContract.getOneTransaction(1);
        assertEq(tx.executed, true);

        assertGt(owner3.balance, balanceBefore); // recipient received funds
    }

    function test_NotExecutedIfThresholdNotReached() public {
        vm.prank(owner1);
        multisigContract.depositEther{value: 1 ether}();

        vm.prank(owner1);
        multisigContract.createATransaction(owner2, 100);

        vm.prank(owner2);
        multisigContract.approveTransaction(1);

        Multisig.Transaction memory tx = multisigContract.getOneTransaction(1);
        assertEq(tx.executed, false);
    }
}
