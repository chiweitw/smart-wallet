// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WalletStorage {
    struct Transaction {
       address to;
       uint value;
       bytes data;
       bool executed;
       mapping(address => bool) confirmations;
	   uint confirmationCount;
	}

    // constants
    uint256 public constant OWNER_LIMIT = 3;
    uint256 public constant CONFIRMATION_NUM = 2;

    // state variables
    address admin;
    mapping(address => bool) public owners;
    Transaction[] public transactions;
}