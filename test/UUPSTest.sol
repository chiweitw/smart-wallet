// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { UUPSProxy } from "../src/UUPSProxy.sol";
import { Wallet, WalletV2 } from "../src/Wallet/WalletV2.sol";

contract UUPSTest is Test {

  address public admin = makeAddr("admin");
  address public alice = makeAddr("alice");
  address public bob = makeAddr("bob");
  address public carol = makeAddr("carol");
  address public receiver = makeAddr("receiver");

  UUPSProxy proxy;
  Wallet wallet;
  WalletV2 walletV2;
  Wallet proxyWallet;
  WalletV2 proxyWalletV2;

  function setUp() public {
    vm.startPrank(admin);
    wallet = new Wallet();
    walletV2 = new WalletV2();
    proxy = new UUPSProxy(
      abi.encodeWithSelector(wallet.initialize.selector, [alice, bob, carol]),
      address(wallet)
    );
    vm.stopPrank();
  }

  function test_UUPS_updateCodeAddress_success() public {
    proxyWallet = Wallet(address(proxy));
    // TODO:
    // 1. check if proxy is correctly proxied,  assert that proxyWallet.VERSION() is "0.0.1"
    assertEq(proxyWallet.VERSION(), "0.0.1");
    // 2. upgrade to WalletV2 by calling updateCodeAddress
    vm.prank(admin);
    proxyWallet.updateCodeAddress(address(walletV2), "");
    // 3. assert that proxyWallet.VERSION() is "0.0.2"
     assertEq(proxyWallet.VERSION(), "0.0.2");
    // 4. assert updateCodeAddress is gone by calling updateCodeAddress with low-level call for Wallet
    vm.expectRevert();
    Wallet(proxyWallet).updateCodeAddress(address(walletV2), "");
  }
}