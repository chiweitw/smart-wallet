// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { HelperTest } from "./Helper.t.sol";

contract OwnerManagerTest is HelperTest {
    function testAddOwnerAndConfirmationNumber() public {
        // orginal owners = [alice, bob, carol], by default alice is the admin;
        // original confirmationNum = 2;
        vm.startPrank(alice);
        wallet.addOwnerAndConfirmationNumber(someone, 3);
        vm.stopPrank();

        assertEq(wallet.isOwner(someone), true);
        assertEq(wallet.confirmationNum(), 3);
    }

    function testConfirmationNumberCannotMoreThanOwnerCountWhenAddOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Invalid confirmation number");
        wallet.addOwnerAndConfirmationNumber(someone, 5);
        vm.stopPrank();
    }

    function testRemoveOwnerAndConfirmationNumber() public {
        vm.startPrank(alice);
        wallet.removeOwnerAndConfirmationNumber(carol, 1);
        vm.stopPrank();

        assertEq(wallet.isOwner(carol), false);
        assertEq(wallet.confirmationNum(), 1);
    }

    function testConfirmationNumberCannotMoreThanOwnerCountWhenRemoveOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Invalid confirmation number");
        wallet.removeOwnerAndConfirmationNumber(carol, 3);
        vm.stopPrank();
    }
}