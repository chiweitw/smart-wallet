// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { UUPSProxy } from "../src/UUPSProxy.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { WalletFactory } from "../src/Wallet/WalletFactory.sol";

contract HelperTest is Test {
	uint256 constant salt = 1234;
	uint256 constant initBalance = 1 ether;

    address[] public owners;
    IEntryPoint entryPoint;
	address public admin;
	address public alice;
	address public bob;
	address public carol;
	address public receiver = makeAddr("receiver");

	UUPSProxy proxy;
	WalletFactory factory;
	Wallet wallet;

	function setUp() public virtual {
		// users
		admin = makeAddr("admin");
		alice = makeAddr("alice");
		bob = makeAddr("bob");
		carol = makeAddr("carol");
		receiver = makeAddr("receiver");

		// set owners
		owners = [alice, bob, carol];

		// Deploy EntryPoint
		entryPoint = new EntryPoint();

		// Deploy Factory and Wallet
		vm.startPrank(admin);
		factory = new WalletFactory(entryPoint);
		wallet = factory.createWallet(owners, salt);

		// init balance
		deal(admin, initBalance);
		deal(alice, initBalance);
		deal(bob, initBalance);
		deal(carol, initBalance);
		deal(address(wallet), initBalance);
		
		vm.stopPrank();

		vm.label(address(entryPoint), "entry point");
	}
}