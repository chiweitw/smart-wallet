// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { HelperTest } from "./Helper.t.sol";
import { WalletStorage } from "../src/Wallet/WalletStorage.sol";

contract WalletTest is HelperTest {
	event SubmitTransaction(address indexed owner, uint indexed nonce);
	event ConfirmTransaction(address indexed owner, uint indexed nonce);
	event ExecuteTransaction(address indexed owner, uint indexed nonce);
	event ExecuteTransactionFailure(address indexed owner, uint indexed nonce);

    function testReceive() public {
        uint amount = 0.01 ether;
        vm.prank(alice);
        payable(address(wallet)).transfer(amount);
        assertEq(address(wallet).balance, initBalance + amount);
        assertEq(alice.balance, initBalance - amount);
    }

    function testSubmitTransaction() public {
        vm.startPrank(alice);
        // submit Tx and 1st confirmation
        vm.expectEmit(true, true, true, true);
        emit SubmitTransaction(alice, 0);
        vm.expectEmit(true, true, true, true);
        emit ConfirmTransaction(alice, 0);
        HelperTest.submitBatchTransaction(HelperTest.signedBatchMessage());
        // epect execution failure when confirmation not enough
        vm.expectEmit(true, true, true, true);
        emit ExecuteTransactionFailure(alice, 0);
        wallet.executeTransaction(0);

        vm.stopPrank();
        // 2nd confirmation
        vm.startPrank(bob);
        vm.expectEmit(true, true, true, true);
        emit ConfirmTransaction(bob, 0);
        vm.expectEmit(true, true, true, true);
        emit ExecuteTransaction(bob, 0);
        HelperTest.confirmBatchTransaction();
        vm.stopPrank();

        assertEq(bob.balance, initBalance + 0.01 ether);
        assertEq(address(wallet).balance, initBalance - 0.01 ether);
    }

    function testSubmitTransactionByNotOwnerOrEntryPoint() public {
        vm.startPrank(someone);
        vm.expectRevert("Only Owner or EntryPoint");
        wallet.executeTransaction(0);
        vm.stopPrank();
    }

    function testSubmitTransactionWithInvalidSignature() public {
        vm.startPrank(alice);
        // submit Tx and 1st confirmation
        vm.expectRevert("Invalid signature");
        HelperTest.submitBatchTransaction(HelperTest.invalidMessage());
    }
}