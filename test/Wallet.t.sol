// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { HelperTest } from "./Helper.t.sol";
import { WalletStorage } from "../src/Wallet/WalletStorage.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

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
        submitBatchTransaction(wallet, multiTransferTxns(1), alicePrivateKey);
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
        confirmBatchTransaction(wallet, multiTransferTxns(1), bobPrivateKey);
        vm.stopPrank();

        assertEq(bob.balance, initBalance + 1 ether);
        assertEq(address(wallet).balance, initBalance - 1 ether);
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
        wallet.submitTransaction(multiTransferTxns(1), createSignature(signedInvalidMessage(), alicePrivateKey, vm));
    }

    function testRevokeConfirmation() public {
        vm.startPrank(alice);
        // alice submit and confirm
        submitBatchTransaction(wallet, multiTransferTxns(1), alicePrivateKey);
        // alice revoke
        revokeBatchTransaction(wallet, multiTransferTxns(1), alicePrivateKey);
        assertEq(wallet.getConfirmationCount(0), 0);
    }

    /*
     * Batch Transaction Benchmarking
     */

    //  Single Transfer Transaction
    function testMultiTransfer1() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiTransferTxns(1), alicePrivateKey);
        vm.stopPrank();

        assertEq(bob.balance, initBalance + 1 ether);
        assertEq(address(singleConfirmWallet).balance, initBalance - 1 ether);
    }

    //  5 Transfer Transaction
    function testMultiTransfer5() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiTransferTxns(5), alicePrivateKey);
        vm.stopPrank();

        assertEq(bob.balance, initBalance + 5 ether);
        assertEq(address(singleConfirmWallet).balance, initBalance - 5 ether);
    }

    //  10 Transfer Transaction
    function testMultiTransfer10() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiTransferTxns(10), alicePrivateKey);
        vm.stopPrank();

        assertEq(bob.balance, initBalance + 10 ether);
        assertEq(address(singleConfirmWallet).balance, initBalance - 10 ether);
    }

    // 50 Transfer Transaction in a batch
    function testMultiTransfer50() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiTransferTxns(50), alicePrivateKey);
        vm.stopPrank();

        assertEq(bob.balance, initBalance + 50 ether);
        assertEq(address(singleConfirmWallet).balance, initBalance - 50 ether);
    }

    // 100 Transfer Transaction in a batch
    function testMultiTransfer100() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiTransferTxns(100), alicePrivateKey);
        vm.stopPrank();

        assertEq(bob.balance, initBalance + 100 ether);
        assertEq(address(singleConfirmWallet).balance, initBalance - 100 ether);
    }

    // Single Swap Transaction
    function testMultiSwap1() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiSwapTxns(1), alicePrivateKey);
        vm.stopPrank();

        assertEq(address(singleConfirmWallet).balance, initBalance - 1 ether);
        assertGt(ERC20(DAI).balanceOf(address(singleConfirmWallet)), 0);
    }

    // 5 Swap Transaction in a batch
    function testMultiSwap5() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiSwapTxns(5), alicePrivateKey);
        vm.stopPrank();

        assertEq(address(singleConfirmWallet).balance, initBalance - 5 ether);
        assertGt(ERC20(DAI).balanceOf(address(singleConfirmWallet)), 0);
    }

    // 10 Swap Transaction in a batch
    function testMultiSwap10() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiSwapTxns(10), alicePrivateKey);
        vm.stopPrank();

        assertEq(address(singleConfirmWallet).balance, initBalance - 10 ether);
        assertGt(ERC20(DAI).balanceOf(address(singleConfirmWallet)), 0);
    }

    // 50 Swap Transaction in a batch
    function testMultiSwap50() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiSwapTxns(50), alicePrivateKey);
        vm.stopPrank();

        assertEq(address(singleConfirmWallet).balance, initBalance - 50 ether);
        assertGt(ERC20(DAI).balanceOf(address(singleConfirmWallet)), 0);
    }

    // 100 Swap Transaction in a batch
    function testMultiSwap100() public {
        // submit Tx and 1st confirmation
        vm.startPrank(alice);
        submitBatchTransaction(singleConfirmWallet, multiSwapTxns(100), alicePrivateKey);
        vm.stopPrank();

        assertEq(address(singleConfirmWallet).balance, initBalance - 100 ether);
        assertGt(ERC20(DAI).balanceOf(address(singleConfirmWallet)), 0);
    }
}