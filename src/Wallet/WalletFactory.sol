// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Wallet.sol";

// contract for creating wallets. 
contract WalletFactory {
    Wallet public immutable walletImplementation;

    constructor(IEntryPoint _entryPoint) {
        walletImplementation = new Wallet(_entryPoint);
    }

    // Todo:
    // 1. create wallet
}