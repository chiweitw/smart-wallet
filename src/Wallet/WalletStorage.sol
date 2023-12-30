// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract WalletStorage {
    struct Transaction {
       address to;
       uint value;
       bytes data;
       bool executed;
	   uint confirmationCount;
	}

    // constants
    uint256 public constant OWNER_LIMIT = 3;
    uint256 public constant CONFIRMATION_NUM = 2;

    // state variables
    IEntryPoint public entryPoint;
    address admin;
    mapping(address => bool) public owners;
    mapping(uint => Transaction) public transactions;
    uint public txId = 0;
}