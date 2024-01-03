// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { HelperTest } from "./Helper.t.sol";
import { WalletStorage } from "../src/Wallet/WalletStorage.sol";

contract WalletTest is HelperTest {
    function testReceive() public {
        uint amount = 0.01 ether;
        vm.prank(alice);
        payable(address(wallet)).transfer(amount);
        assertEq(address(wallet).balance, initBalance + amount);
        assertEq(alice.balance, initBalance - amount);
    }

    function testTransfer() public {
        vm.startPrank(alice);
        // submit Tx
        HelperTest._submitTransferTransaction();
        // 1st confirmation
        wallet.confirmTransaction(0);
        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(0);
        vm.stopPrank();
        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(0);
        vm.prank(alice);
        wallet.executeTransaction(0);
        assertEq(bob.balance, initBalance + 0.01 ether);
        assertEq(address(wallet).balance, initBalance - 0.01 ether);
    }

    function testTransferByEntryPoint() public {
        vm.startPrank(alice);
        // submit Tx
        HelperTest._submitTransferTransaction();
        // 1st confirmation
        wallet.confirmTransaction(0);
        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(0);
        vm.stopPrank();
        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(0);
        vm.prank(address(entryPoint));
        wallet.executeTransaction(0);

        assertEq(bob.balance, initBalance + 0.01 ether);
        assertEq(address(wallet).balance, initBalance - 0.01 ether);
    }

    function testTransferByNotOwnerOrEntryPoint() public {
        vm.startPrank(alice);
        // submit Tx
        HelperTest._submitTransferTransaction();
        // 1st confirmation
        wallet.confirmTransaction(0);
        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(0);
        vm.stopPrank();
        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(0);
        vm.prank(someone);
        vm.expectRevert("Only Owner or EntryPoint");
        wallet.executeTransaction(0);
    }

    function testTransferERC20() public {
        vm.startPrank(alice);
        // submit Tx
        HelperTest._submitTransferERC20Transaction();
        // 1st confirmation
        wallet.confirmTransaction(0);
        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(0);
        vm.stopPrank();
        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(0);
        vm.prank(alice);
        wallet.executeTransaction(0);

        assertEq(testErc20.balanceOf(bob), initERC20Balance + 1e18);
        assertEq(testErc20.balanceOf(address(wallet)), initERC20Balance - 1e18);
    }
}