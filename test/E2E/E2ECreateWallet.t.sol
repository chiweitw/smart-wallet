// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console, Vm } from "forge-std/Test.sol";
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { WalletFactory } from "../../src/Wallet/WalletFactory.sol";
import { Wallet } from "../../src/Wallet/Wallet.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract E2ECreateWalletTest is Test {
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
    }

    function testE2ECreateWallet() public {
        vm.startPrank(alice);

        // Create wallet through user operations
        UserOperation[] memory userOperations = new UserOperation[](1);

        // initCode to create wallet
        bytes memory initCode = abi.encodePacked(
            abi.encodePacked(address(factory)),
            abi.encodeWithSelector(WalletFactory.createWallet.selector, owners, confirmationNum, salt)
        );

        // userOperation object
        UserOperation memory userOperation = UserOperation({
            sender: sender,
            nonce: 0,
            initCode: initCode,
            callData: "",
            callGasLimit: 1_000_000,
            verificationGasLimit: 1_000_000,
            preVerificationGas: 1_000_000,
            maxFeePerGas: 1_000_000,
            maxPriorityFeePerGas: 1_000_000,
            paymasterAndData: "",
            signature: ""
        });

        // Sign userOperation and add signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOperation);
        bytes memory signature = createSignature(userOpHash, alicePrivateKey, vm);
        userOperation.signature = signature;
        
        userOperations[0] = userOperation;

        // EntryPoiny handle Operations
        entryPoint.handleOps(userOperations, beneficiary);

        // Check if wallet was created
        uint256 codeSize = sender.code.length;

        assertGt(codeSize, 0, "Wallet was not created");
        assertEq(Wallet(sender).initialized(), true, "Wallet was not initialized");
        assertEq(address(Wallet(sender).entryPoint()), address(entryPoint));

        vm.stopPrank();
    }

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
}