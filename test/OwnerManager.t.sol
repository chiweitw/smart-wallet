// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { HelperTest } from "./Helper.t.sol";

contract OwnerManagerTest is HelperTest {
    // orginal owners = [alice, bob, carol], by default alice is the admin;
    // original confirmationNum = 2;
    function testAddOwnerAndConfirmationNumber() public {
        vm.startPrank(alice);
        wallet.addOwnerAndConfirmationNumber(someone, 3);
        vm.stopPrank();

        assertEq(wallet.isOwner(someone), true);
        assertEq(wallet.confirmationNum(), 3);
        assertEq(wallet.getOwnerCount(), 4);
    }

    function testOnlyAdminCanAddOwner() public {
        vm.startPrank(bob);
        vm.expectRevert("Only Admin");
        wallet.addOwnerAndConfirmationNumber(someone, 3);
        vm.stopPrank();
    }

    function testConfirmationNumberCannotMoreThanOwnerWhenAdd() public {
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
        assertEq(wallet.getOwnerCount(), 2);
    }

    function testOnlyAdminCanRemoveOwner() public {
        vm.startPrank(bob);
        vm.expectRevert("Only Admin");
        wallet.addOwnerAndConfirmationNumber(carol, 1);
        vm.stopPrank();
    }

    function testConfirmationNumberCannotMoreThanOwnerWhenRemove() public {
        vm.startPrank(alice);
        vm.expectRevert("Invalid confirmation number");
        wallet.removeOwnerAndConfirmationNumber(carol, 3);
        vm.stopPrank();
    }

    function testAddAdmin() public {
        vm.startPrank(alice);
        wallet.addAdmin(bob);
        vm.stopPrank();

        assertEq(wallet.isAdmin(bob), true);
    }

    function testAddAdminByNonAdmin() public {
        vm.startPrank(bob);
        vm.expectRevert("Only Admin");
        wallet.addAdmin(carol);
        vm.stopPrank();
    }

    function testAddNonOwnerToAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert("Owner not existed");
        wallet.addAdmin(address(0));
        vm.stopPrank();
    }

    function testLeaveParty() public {
        vm.startPrank(bob);
        wallet.leaveParty();
        vm.stopPrank();
        assertEq(wallet.isOwner(bob), false);
        assertEq(wallet.getOwnerCount(), 2);
    }

    function testLeavePartyAdminCannotBeZero() public {
        vm.startPrank(alice);
        vm.expectRevert("Admin cannot be zero");
        wallet.leaveParty();
        vm.stopPrank();
    }
}