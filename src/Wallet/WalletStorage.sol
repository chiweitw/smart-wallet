// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WalletStorage {
    uint256 public constant OWNER_LIMIT = 3;
    uint256 public constant CONFIRMATION_NUM = 2;
    address admin;
    address[] owners;
}