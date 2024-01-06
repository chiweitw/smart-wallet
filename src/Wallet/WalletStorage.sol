// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract WalletStorage {
    /*
     *  Structs
     */
    struct Transaction {
       address to;
       uint value;
       bytes data;
	}

    /*
     *  Constants
     */
    uint256 public constant OWNER_LIMIT = 3;

    /*
     *  Storage
     */
    IEntryPoint public immutable _entryPoint;
    uint256 public nonce;
    uint256 public confirmationNum;
    address[] public owners;
    address admin;
    mapping (address => bool) public isOwner;
    mapping (uint256 => Transaction[]) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (uint256 => bool) public isExecuted;
}