// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { WalletFactory } from "../src/Wallet/WalletFactory.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { HelperTest } from "./Helper.t.sol";

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
}