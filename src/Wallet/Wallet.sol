// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/Test.sol";

import { Proxiable } from "../utils/Proxiable.sol";
import { Slots } from "../utils/Slots.sol";
import { WalletStorage } from "./WalletStorage.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract Wallet is Proxiable, Slots, WalletStorage {
	bool public initialized;

	event SubmitTransaction(address indexed owner, uint indexed txId, address indexed to, uint value, bytes data);
	event ConfirmTransaction(address indexed owner, uint indexed txId);
	event ExecuteTransaction(address indexed owner, uint indexed txId);

	modifier onlyAdmin {
		require(msg.sender == admin, "Only Admin");
		_; 
	}

	modifier onlyOwner {
		require(owners[msg.sender] == true);
		_;
	}

	modifier onlyOwnerOrEntryPoint {
		require(msg.sender == address(_entryPoint) || owners[msg.sender], "Not Owner or EntryPoint");
		_;
	}

	constructor(IEntryPoint anEntryPoint) {
		_entryPoint = anEntryPoint;
	}

	function initialize(address[] memory _owners) external {
		require(initialized == false, "already initialized");
		require(_owners.length > 1, "owners required must grater than 1");
		require(_owners.length >= CONFIRMATION_NUM, "Num of confirmation is not sync with num of owner");
		admin = msg.sender;
		for (uint256 i=0; i < _owners.length; i++) {
			require(_owners[i]!=address(0), "Invalid Owner");
			owners[_owners[i]] = true;
		}
		initialized = true;
	}

	function updateCodeAddress(address newImplementation, bytes memory data) external onlyAdmin {
		// TODO:
		// 1. check if newimplementation is compatible with proxiable
		// 2. update the implementation address
		// 3. initialize proxy, if data exist, then initialize proxy with _data
		require(Proxiable(newImplementation).proxiableUUID() == proxiableUUID(), "No Proxiable");

		_setSlotToAddress(proxiableUUID(), newImplementation);

		if (data.length > 0) {
			(bool success,) = newImplementation.delegatecall(data);
			require(success);
		}
	}

	// execute a transaction (called directly from owner, or by entryPoint)
    function execute(address dest, uint256 value, bytes calldata func) external onlyOwnerOrEntryPoint {
        _call(dest, value, func);
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

	// Multi-Sig
	// Submit Transaction
	function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner returns (uint txId) {
		uint256 currentTxId = txId;
		transactions[txId] = Transaction({
			to: _to,
			value: _value,
			data: _data,
			executed: false,
			confirmationCount: 0
        });

		txId++;

		emit SubmitTransaction(msg.sender, txId, _to, _value, _data);

		return currentTxId;
	}

	// Confirm Transaction
	function confirmTransaction(uint txId) external onlyOwner {
		Transaction storage transaction = transactions[txId];
		transaction.confirmationCount++;

		emit ConfirmTransaction(msg.sender, txId);

	}
	// Execute Transaction
	function executeTransaction (uint txId) external onlyOwnerOrEntryPoint {
		Transaction memory transaction = transactions[txId];
		require(transaction.confirmationCount >= CONFIRMATION_NUM, "Confirmations not enough.");
		(bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

		require(success, "transaction failed");
		transaction.executed = true;
		emit ExecuteTransaction(msg.sender, txId);
	}

	function VERSION() external view virtual returns (string memory) {
		return "0.0.1";
	}
}