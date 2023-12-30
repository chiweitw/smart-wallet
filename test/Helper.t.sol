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

    address[] public owners;
    IEntryPoint entryPoint;
	address public admin = makeAddr("admin");
	address public alice = makeAddr("alice");
	address public bob = makeAddr("bob");
	address public carol = makeAddr("carol");
	address public receiver = makeAddr("receiver");

	UUPSProxy proxy;
	WalletFactory factory;
	Wallet wallet;

	function setUp() public virtual {
		// set owners
		owners = [alice, bob, carol];

		// Deploy EntryPoint
		entryPoint = new EntryPoint();

		// Deploy Factory and Wallet
		vm.startPrank(admin);
		factory = new WalletFactory(entryPoint);
		wallet = factory.createWallet(owners, salt);
		
		vm.stopPrank();

		vm.label(address(entryPoint), "entry point");
	}
}