// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { UUPSProxy } from "../src/UUPSProxy.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { WalletFactory } from "../src/Wallet/WalletFactory.sol";
import { TestERC20 } from "../src/Test/TestErc20.sol";

contract HelperTest is Test {
	uint256 constant salt = 1234;
    address[] public owners;
    IEntryPoint entryPoint;
	address public admin;
	address public alice;
	address public bob;
	address public carol;
	address public someone;

	UUPSProxy proxy;

	// Factory
	WalletFactory factory;

	// Wallet
	Wallet wallet;
	uint256 confirmationNum = 2;

	// Test Token
	TestERC20 testErc20;

	uint256 initBalance;
	uint256 initERC20Balance;

	function setUp() public virtual {
		// users
		admin = makeAddr("admin");
		alice = makeAddr("alice");
		bob = makeAddr("bob");
		carol = makeAddr("carol");
		someone = makeAddr("someone");

		// set owners
		owners = [alice, bob, carol];

		// Deploy EntryPoint
		entryPoint = new EntryPoint();

		// Deploy Factory and Wallet
		vm.startPrank(admin);
		factory = new WalletFactory(entryPoint);

		// pre-determined wallet address
		wallet = factory.createWallet(owners, confirmationNum, salt);

		// set ERC20 Token
		testErc20 = new TestERC20();

		// init balance
		initBalance = 1 ether;
		deal(admin, initBalance);
		deal(alice, initBalance);
		deal(bob, initBalance);
		deal(carol, initBalance);
		deal(address(wallet), initBalance);

		// init ERC20 balance
		initERC20Balance = 100e18;
		deal(address(testErc20), admin, initERC20Balance);
		deal(address(testErc20), alice, initERC20Balance);
		deal(address(testErc20), bob, initERC20Balance);
		deal(address(testErc20), carol, initERC20Balance);
		deal(address(testErc20), address(wallet), initERC20Balance);
		
		vm.stopPrank();

		vm.label(address(entryPoint), "entry point");
	}
}