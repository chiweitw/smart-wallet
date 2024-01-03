// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract WalletStorage {
    struct Transaction {
       address to;
       uint value;
       bytes data;
	}

    // constants
    uint256 public constant OWNER_LIMIT = 3;

    // state variables
    IEntryPoint public immutable _entryPoint;
    address admin;
    uint256 public _confirmationNum;
    mapping(address => bool) public owners;
    mapping(uint256 => Transaction[]) public transactions;
    mapping(uint256 => uint256) public confirmationCounts;
    uint256 public nonce;
}