// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console, Vm } from "forge-std/Test.sol";
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { WalletFactory } from "../src/Wallet/WalletFactory.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { WalletStorage } from "../src/Wallet/WalletStorage.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { TestERC20 } from "../src/Test/TestErc20.sol";
import { HelperTest } from "./Helper.t.sol";

contract UserOperationTest is HelperTest {
    function testCreateWallet() public {
        vm.startPrank(bob);
        // Pre-compute address
        sender = factory.getAddress(owners, confirmationNum, 321);
        deal(sender, initBalance);
        
        // initCode to create wallet
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(factory)),
            abi.encodeWithSelector(WalletFactory.createWallet.selector, owners, confirmationNum, 321)
        );
        // create userOperation
        UserOperation memory userOp = createUserOp(0, initCode, "");
        // Sign userOperation and add signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = HelperTest.createSignature(userOpHash, bobPrivateKey, vm);
        userOp.signature = signature;

        vm.stopPrank();

        vm.startPrank(beneficiary); // bundler 
        // EntryPoiny handle Operations
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;   
        entryPoint.handleOps(userOps, beneficiary);

        // Check if wallet was created
        uint256 codeSize = sender.code.length;
        assertGt(codeSize, 0, "Wallet was not created");
        assertEq(Wallet(sender).initialized(), true, "Wallet was not initialized");
        assertEq(address(Wallet(sender).entryPoint()), address(entryPoint));

        vm.stopPrank();
    }

    function testSubmitTransaction() public {
        // Create wallet
        Wallet wallet = factory.createWallet(owners, confirmationNum, salt);
        vm.startPrank(alice);
        // Calldata
        bytes32 messageHash = keccak256(abi.encodePacked(Wallet.submitTransaction.selector, abi.encode(HelperTest.batchTxns())));
        bytes memory sig = HelperTest.createSignature(messageHash, alicePrivateKey, vm);
        bytes memory callData = abi.encodeCall(Wallet.submitTransaction, (HelperTest.batchTxns(), sig));
        // create userOperation
        UserOperation memory userOp = createUserOp(Wallet(sender).getNonce(), "", callData);
        // signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = HelperTest.createSignature(userOpHash, alicePrivateKey, vm);
        userOp.signature = signature;
        vm.stopPrank();
        vm.startPrank(beneficiary);
        // EntryPoiny handle Operations
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;   
        entryPoint.handleOps(userOps, beneficiary);
        vm.stopPrank();
        // Check wallet created
        uint256 codeSize = sender.code.length;
        assertGt(codeSize, 0, "Wallet was not created");
        assertEq(Wallet(sender).initialized(), true, "Wallet was not initialized");
        // Check transaction submitted
        // transfer ETH
        assertEq(wallet.getTransaction(0)[0].to, bob);
        assertEq(wallet.getTransaction(0)[0].value, 0.01 ether);
        assertEq(wallet.getTransaction(0)[0].data, "");
        // transfer ERC20
        assertEq(wallet.getTransaction(0)[1].to, address(testErc20));
        assertEq(wallet.getTransaction(0)[1].value, 0);
        assertEq(wallet.getTransaction(0)[1].data, abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18));
        // confitmation counts
        assertEq(wallet.getConfirmationCount(0), 1);
    }

    function testConfirmAndExecuteTransaction() public {
        testSubmitTransaction();

        WalletStorage.Transaction[] memory txns = wallet.getTransaction(0);
        bytes32 messageHash = keccak256(abi.encodePacked(Wallet.submitTransaction.selector, abi.encode(txns)));
        bytes memory sig = HelperTest.createSignature(messageHash, bobPrivateKey, vm);
        // calldata
        bytes memory callData = abi.encodeCall(Wallet.confirmTransaction, (0, sig));
        vm.startPrank(bob);
        // signature
        UserOperation memory userOp2 = createUserOp(Wallet(sender).getNonce(), "", callData);
        bytes32 userOpHash2 = entryPoint.getUserOpHash(userOp2);
        bytes memory signature2 = HelperTest.createSignature(userOpHash2, bobPrivateKey, vm);
        userOp2.signature = signature2;
        vm.stopPrank();
        // EntryPoiny handle Operations
        vm.startPrank(beneficiary);
        UserOperation[] memory userOps2 = new UserOperation[](1);
        userOps2[0] = userOp2;  
        entryPoint.handleOps(userOps2, beneficiary);
        vm.stopPrank();

        assertEq(wallet.getConfirmationCount(0), 2);
        assertEq(testErc20.balanceOf(bob), initERC20Balance + 1e18);
        assertEq(testErc20.balanceOf(sender), initERC20Balance - 1e18);
        assertEq(bob.balance, initBalance + 0.01 ether);
        assertLt(sender.balance, initBalance - 0.01 ether); // sender transfer 0.01 ether + gas fee
    }

    function createUserOp(uint256 nonce, bytes memory initCode, bytes memory callData) public view returns (UserOperation memory) {
        return UserOperation({
            sender: sender,
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            callGasLimit: 1_000_000,
            verificationGasLimit: 1_000_000,
            preVerificationGas: 1_000_000,
            maxFeePerGas: 10_000_000_000,
            maxPriorityFeePerGas: 2_500_000_000,
            paymasterAndData: "",
            signature: ""
        });
    }
}