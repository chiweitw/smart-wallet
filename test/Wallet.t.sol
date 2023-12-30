// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console } from "forge-std/Test.sol";
import { HelperTest } from "./Helper.t.sol";

contract WalletTest is HelperTest {
    function testSubmitTransaction() public {
        // Todo:
        // Submit transaction
        // Check TxId
        // Check confirmation_count is 0
        // expect emit SubmitTransaction event
    }

    function testConfirmTransaction() public {
        // Todo:
        // Confirm transaction
        // 1st Confirm...
        // Check confirmation_count is 1
        // expect emit ConfirmTransaction event
    }

    function testExecuteTransaction() public {
        // Todo:
        // Execute transaction
        // Submit Tx
        // 1st confirm and execute
        // expect to revert
        // 2nd confirm and execute
        // expect emit ExecuteTransaction event
    }
}