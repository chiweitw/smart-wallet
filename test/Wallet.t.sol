// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { HelperTest } from "./Helper.t.sol";

contract WalletTest is HelperTest {
    struct Transaction {
       address to;
       uint value;
       bytes data;
	   uint confirmationCount;
	}

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
        uint256 txId = wallet.submitTransaction(bob, 0.01 ether, "");

        // 1st confirmation
        wallet.confirmTransaction(txId);

        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(txId);
        vm.stopPrank();

        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(txId);

        vm.prank(alice);
        wallet.executeTransaction(txId);

        // execute Tx
        // wallet.execute(bob, 0.01 ether, "");
        assertEq(bob.balance, initBalance + 0.01 ether);
        assertEq(address(wallet).balance, initBalance - 0.01 ether);
    }

    function testTransferByEntryPoint() public {
        vm.startPrank(alice);
        // submit Tx
        uint256 txId = wallet.submitTransaction(bob, 0.01 ether, "");

        // 1st confirmation
        wallet.confirmTransaction(txId);

        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(txId);
        vm.stopPrank();

        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(txId);

        vm.prank(address(entryPoint));
        wallet.executeTransaction(txId);

        // execute Tx
        // wallet.execute(bob, 0.01 ether, "");
        assertEq(bob.balance, initBalance + 0.01 ether);
        assertEq(address(wallet).balance, initBalance - 0.01 ether);
    }

    function testTransferByNotOwnerOrEntryPoint() public {
        vm.startPrank(alice);
        // submit Tx
        uint256 txId = wallet.submitTransaction(bob, 0.01 ether, "");

        // 1st confirmation
        wallet.confirmTransaction(txId);

        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(txId);
        vm.stopPrank();

        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(txId);

        vm.prank(someone);
        vm.expectRevert("Only Owner or EntryPoint");
        wallet.executeTransaction(txId);
    }

    function testTransferERC20() public {
        vm.startPrank(alice);
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18);

        // submit Tx
        uint256 txId = wallet.submitTransaction(address(testErc20), 0, data);
        // 1st confirmation
        wallet.confirmTransaction(txId);
        vm.expectRevert("Confirmations not enough.");
        wallet.executeTransaction(txId);
        vm.stopPrank();

        // 2nd confirmation and execute again
        vm.prank(bob);
        wallet.confirmTransaction(txId);

        vm.prank(alice);
        wallet.executeTransaction(txId);

        // wallet.execute(address(testErc20), 0, data);
        assertEq(testErc20.balanceOf(bob), initERC20Balance + 1e18);
        assertEq(testErc20.balanceOf(address(wallet)), initERC20Balance - 1e18);
    }
}