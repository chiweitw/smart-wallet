// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { WalletFactory } from "../src/Wallet/WalletFactory.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { HelperTest } from "./Helper.t.sol";

contract WalletFactoryTest is HelperTest {
    function testCreateWallet() public {
        address walletAddress = factory.getAddress(owners, salt);

        assertEq(wallet.initialized(), true);

        // The computed address should be equal to the deployed address
        assertEq(address(wallet), walletAddress);
    }
}