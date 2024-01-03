// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { WalletStorage } from "./WalletStorage.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { BaseAccount } from "account-abstraction/core/BaseAccount.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import { console } from "forge-std/Test.sol";

contract Wallet is BaseAccount, WalletStorage {
	using ECDSA for bytes32;
	using MessageHashUtils for bytes32;

	bool public initialized;

	event SubmitTransaction(address indexed owner, uint indexed nonce);
	event ConfirmTransaction(address indexed owner, uint indexed nonce);
	event ExecuteTransaction(address indexed owner, uint indexed nonce);

	modifier onlyAdmin {
		require(msg.sender == admin, "Only Admin");
		_; 
	}

	modifier onlyOwner {
		require(owners[msg.sender] == true, "Only Owner");
		_;
	}

	modifier onlyOwnerOrEntryPoint {
		require(msg.sender == address(_entryPoint) || owners[msg.sender], "Only Owner or EntryPoint");
		_;
	}

	constructor(IEntryPoint anEntryPoint) {
		_entryPoint = anEntryPoint;
	}

	function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

	function initialize(address[] memory _owners, uint256 confirmationNum) external {
		require(initialized == false, "already initialized");
		require(_owners.length > 1, "owners required must grater than 1");
		require(_owners.length >= confirmationNum, "Num of confirmation is not sync with num of owner");
		admin = msg.sender;
		for (uint256 i=0; i < _owners.length; i++) {
			require(_owners[i]!=address(0), "Invalid Owner");
			owners[_owners[i]] = true;
		}
		initialized = true;
		_confirmationNum = confirmationNum;
	}

	// ERC4337
	// check the signature
	function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
		require(msg.sender == address(_entryPoint), "Only EntryPoint");
        bytes32 hash = userOpHash.toEthSignedMessageHash();
		address signer = ECDSA.recover(hash, userOp.signature);
        if (!owners[signer]) {
            return SIG_VALIDATION_FAILED;
        }
        return 0;
    }

	// Multi-Sig and Batch Transaction
	// Submit Transaction
	function submitTransaction(Transaction[] memory txns) public onlyOwnerOrEntryPoint {
		uint256 currentNonce = nonce;
		for (uint256 i=0; i<txns.length; i++) {
			transactions[currentNonce].push(txns[i]);
		}
		nonce++;

		emit SubmitTransaction(msg.sender, currentNonce);
	}

	// Confirm Transaction
	function confirmTransaction(uint nonce) external onlyOwnerOrEntryPoint {
		confirmationCounts[nonce] = confirmationCounts[nonce] + 1;

		emit ConfirmTransaction(msg.sender, nonce);

	}
	// Execute Transaction
	function executeTransaction (uint nonce) external onlyOwnerOrEntryPoint {
		require(confirmationCounts[nonce] >= _confirmationNum, "Confirmations not enough.");
		Transaction[] memory txns = transactions[nonce];
		executeBatch(txns);
		emit ExecuteTransaction(msg.sender, nonce);
	}

	function executeBatch(Transaction[] memory txns) internal {
		require(txns.length > 0, 'MUST_PASS_TX');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			_call(txn.to, txn.value, txn.data);
		}
	}

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

	function VERSION() external view virtual returns (string memory) {
		return "0.0.1";
	}

	function getTransaction(uint256 nonce) public view virtual returns (Transaction[] memory) {
		return transactions[nonce];
	}
	
	function getConfirmationCounts(uint256 nonce) public view virtual returns (uint256) {
		return confirmationCounts[nonce];
	}
}