// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { WalletFactory } from "../src/Wallet/WalletFactory.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { HelperTest } from "./Helper.t.sol";
import { WalletV2 } from "../src/Wallet/WalletV2.sol";

contract WalletFactoryTest is HelperTest {
    function testCreateWallet() public {
        address walletAddress = factory.getAddress(owners, confirmationNum,salt);

        assertEq(wallet.initialized(), true);

        // The computed address should be equal to the deployed address
        assertEq(address(wallet), walletAddress);

        // The code size > 0
        uint256 codeSize = walletAddress.code.length;
        assertGt(codeSize, 0);

        // check entryPoint
        assertEq(address(entryPoint), address(wallet._entryPoint()));
    }

    function testCreateWalletDuplicateOwnerFailure() public {
        vm.expectRevert("Construction failed");
        address[] memory invalidOwners = new address[](2);
        invalidOwners[0] = alice;
        invalidOwners[1] = alice;
        factory.createWallet(invalidOwners, confirmationNum, salt);
    }

    function testUpgrade() public {
        vm.startPrank(alice);
        assertEq(Wallet(sender).proxiableUUID(), keccak256("PROXIABLE"));
        WalletV2 newImplementation = new WalletV2();
        Wallet(sender).upgradeTo(address(newImplementation));
        vm.stopPrank();
        assertEq(WalletV2(sender).VERSION(), "0.0.2");
    }
}