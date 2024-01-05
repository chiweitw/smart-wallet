// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console, Vm } from "forge-std/Test.sol";
import { UUPSProxy } from "../src/UUPSProxy.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { WalletFactory } from "../src/Wallet/WalletFactory.sol";
import { TestERC20 } from "../src/Test/TestErc20.sol";
import { WalletStorage } from "../src/Wallet/WalletStorage.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract HelperTest is Test {
	uint256 constant salt = 1234;
	// Users
	address[] owners;
	IEntryPoint entryPoint;
	address admin;
	address alice;
	uint256 alicePrivateKey;
	address bob;
	uint256 bobPrivateKey;
	address carol;
	address someone;
	address payable beneficiary;
	address sender;
	// Proxy
	UUPSProxy proxy;
	// Factory
	WalletFactory factory;
	// Wallet
	Wallet wallet;
	uint256 confirmationNum = 2;
	// Test Token
	TestERC20 testErc20;
	uint256 initBalance = 1 ether;
	uint256 initERC20Balance = 100e18;

	function setUp() public virtual {
		// users
		admin = makeAddr("admin");
		(alice, alicePrivateKey) = makeAddrAndKey("alice");
		(bob, bobPrivateKey) = makeAddrAndKey("bob");
		carol = makeAddr("carol");
		someone = makeAddr("someone");
		beneficiary = payable(makeAddr("beneficiary"));
		// set owners
		owners = [alice, bob, carol];
		// Deploy EntryPoint
		entryPoint = new EntryPoint();
		// Deploy Factory and Wallet
		vm.startPrank(admin);
		factory = new WalletFactory(entryPoint);
		// Create Wallet
		sender = factory.getAddress(owners, confirmationNum, salt);
		wallet = factory.createWallet(owners, confirmationNum, salt);
		// set ERC20 Token
		testErc20 = new TestERC20();
		// init balance
		deal(admin, initBalance);
		deal(alice, initBalance);
		deal(bob, initBalance);
		deal(carol, initBalance);
		deal(address(wallet), initBalance);
		// init ERC20 balance
		deal(address(testErc20), admin, initERC20Balance);
		deal(address(testErc20), alice, initERC20Balance);
		deal(address(testErc20), bob, initERC20Balance);
		deal(address(testErc20), carol, initERC20Balance);
		deal(address(testErc20), address(wallet), initERC20Balance);
		
		vm.stopPrank();
	}

	function _transferTxns() internal view returns (WalletStorage.Transaction[] memory txns) {
        txns = new WalletStorage.Transaction[](1);
        txns[0] = WalletStorage.Transaction({
            to: bob,
            value: 0.01 ether,
            data: ""
        });
	}

    function _submitTransferTransaction() internal {
		WalletStorage.Transaction[] memory txns = _transferTxns();
		bytes32 messageHash = keccak256(abi.encode(txns));
        bytes memory sig = _createSignature(messageHash, alicePrivateKey, vm);
        wallet.submitTransaction(txns, sig);
    }

    function _confirmTransferTransaction() internal {
		WalletStorage.Transaction[] memory txns = _transferTxns();
		bytes32 messageHash = keccak256(abi.encode(txns));
        bytes memory sig = _createSignature(messageHash, bobPrivateKey, vm);
        wallet.confirmTransaction(0, sig);
    }

	function _transferERC20Txns() internal view returns (WalletStorage.Transaction[] memory txns) {
        txns = new WalletStorage.Transaction[](1);
        txns[0] = WalletStorage.Transaction({
            to: address(testErc20),
            value: 0,
            data: abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18)
        });
	}

    function _submitTransferERC20Transaction() internal {
        WalletStorage.Transaction[] memory txns = _transferERC20Txns();
		bytes32 messageHash = keccak256(abi.encode(txns));
        bytes memory sig = _createSignature(messageHash, alicePrivateKey, vm);
        wallet.submitTransaction(txns, sig);
    }

    function _confirmTransferERC20Transaction() internal {
		WalletStorage.Transaction[] memory txns = _transferERC20Txns();
		bytes32 messageHash = keccak256(abi.encode(txns));
        bytes memory sig = _createSignature(messageHash, bobPrivateKey, vm);
        wallet.confirmTransaction(0, sig);
    }

    function _createSignature(
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