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

contract E2ETest is Test {
    uint256 constant salt = 1234;
    address[] public owners;
    IEntryPoint entryPoint;
    WalletFactory factory;
    uint256 confirmationNum = 1;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    address carol;
    address sender;
    address payable beneficiary;

	// Test Token
	TestERC20 testErc20;
    uint256 initERC20Balance = 100e18;

    // enum TransactionStatus {
    //     PENDING,
    //     CONFIRMED,
    //     EXECUTED
    // }

    // struct Transaction {
    //    address to;
    //    uint value;
    //    bytes data;
    //    TransactionStatus status;
	//    uint confirmationCount;
	// }

    function setUp() public {
        // users 
        // alice = makeAddr("alice");
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
		bob = makeAddr("bob");
		carol = makeAddr("carol");
        owners = [alice, bob, carol];

        beneficiary = payable(makeAddr("beneficiary"));

        // Deploy EntryPoint
		entryPoint = new EntryPoint();

        // Deploy Factory
        factory = new WalletFactory(entryPoint);

        // Pre-compute sender address
        sender = factory.getAddress(owners, confirmationNum, salt);

        // Init Balance
        deal(sender, 1 ether);

        // set ERC20 Token
		testErc20 = new TestERC20();

        deal(address(testErc20), alice, initERC20Balance);
    }

    function testE2ECreateWallet() public {
        vm.startPrank(alice);

        // initCode to create wallet
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(factory)),
            abi.encodeWithSelector(WalletFactory.createWallet.selector, owners, confirmationNum, salt)
        );

        // create userOperation
        UserOperation memory userOp = createUserOp(initCode, "");

        // Sign userOperation and add signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOpHash, alicePrivateKey, vm);
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

        // calldata
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18);
        bytes memory callData = abi.encodeCall(
            Wallet.submitTransaction, 
            (
                address(testErc20), 
                0, 
                data
            ));

        // create userOperation
        UserOperation memory userOp = createUserOp("", callData);
        
        // signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes memory signature = createSignature(userOpHash, alicePrivateKey, vm);
        userOp.signature = signature;

        vm.stopPrank();

        // EntryPoiny handle Operations
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;   
        entryPoint.handleOps(userOps, beneficiary);

        // Check wallet created
        uint256 codeSize = sender.code.length;
        assertGt(codeSize, 0, "Wallet was not created");
        assertEq(Wallet(sender).initialized(), true, "Wallet was not initialized");

        // Check transaction submitted
        assertEq(wallet.getTransaction(0).to, address(testErc20));
        assertEq(wallet.getTransaction(0).value, 0);
        assertEq(wallet.getTransaction(0).data, data);
        // assertEq(wallet.getTransaction(0).status, WalletStorage.TransactionStatus.PENDING);
        assertEq(wallet.getTransaction(0).confirmationCount, 0);
    }

    // Todo
    // function testConfirmTransaction() public {
    //     testSubmitTransaction();
    //     vm.prank(bob);

    // }

    // function testExecuteTransaction() public {
    // }

    function createSignature(
        bytes32 messageHash,
        uint256 ownerPrivateKey,
        Vm vm
    ) public pure returns (bytes memory) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = bytes.concat(r, s, bytes1(v));
        return signature;
    }

    function createUserOp(bytes memory initCode, bytes memory callData) public view returns (UserOperation memory) {
        return UserOperation({
            sender: sender,
            nonce: 0,
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