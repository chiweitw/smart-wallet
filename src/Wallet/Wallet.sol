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
	using MessageHashUtils for bytes32;

	bool public initialized;

	/*
	 *  Events
	 */
	event SubmitTransaction(address indexed owner, uint indexed nonce);
	event ConfirmTransaction(address indexed owner, uint indexed nonce);
	event RevokeConfirmation(address indexed owner, uint indexed nonce);
	event ExecuteTransaction(address indexed owner, uint indexed nonce);
	event ExecuteTransactionFailure(address indexed owner, uint indexed nonce);

	/*
	 *  Modifiers
	 */
	modifier onlyAdmin {
		require(msg.sender == admin, "Only Admin");
		_; 
	}

	modifier onlyOwner {
		require(isOwner[msg.sender] == true, "Only Owner");
		_;
	}

	modifier onlyOwnerOrEntryPoint {
		require(msg.sender == address(_entryPoint) || isOwner[msg.sender], "Only Owner or EntryPoint");
		_;
	}

	modifier notExecuted(uint256 nonce) {
		require(!isExecuted[nonce], "Already Executed");
		_;
	}

	/*
	 *  Constructor
	 */
	constructor(IEntryPoint anEntryPoint) {
		_entryPoint = anEntryPoint;
	}

	function entryPoint() public view virtual override returns (IEntryPoint) {
		return _entryPoint;
	}

	function initialize(address[] memory _owners, uint256 _confirmationNum) external {
		require(initialized == false, "already initialized");
		require(_owners.length >= confirmationNum, "Num of confirmation is not sync with num of owner");
		admin = msg.sender;
		// owners = _owners;
		for (uint256 i=0; i < _owners.length; i++) {
			require(_owners[i] != address(0) && !isOwner[_owners[i]], "Invalid Owner");
			isOwner[_owners[i]] = true;
			owners.push(_owners[i]);
		}
		initialized = true;
		confirmationNum = _confirmationNum;
	}

	/// @dev Allows an owner to submit and confirm a transaction.
	/// @param txns Transactions.
	/// @param signature Signer's signature.
	function submitTransaction(Transaction[] memory txns, bytes calldata signature) public onlyOwnerOrEntryPoint {
		_isValidSignature(keccak256(abi.encodePacked(this.submitTransaction.selector, abi.encode(txns))), signature);
		uint256 nonce = _addTransaction(txns);
		confirmTransaction(nonce, signature);

		emit SubmitTransaction(msg.sender, nonce);
	}

	/// @dev Allows an owner or entry point to confirm a transaction.
	/// @param nonce Transaction Nonce.
	/// @param signature Signer's signature.
	function confirmTransaction(uint256 nonce, bytes calldata signature) public onlyOwnerOrEntryPoint {
		Transaction[] memory txns = getTransaction(nonce);
		address signer = _getSigner(keccak256(abi.encodePacked(this.submitTransaction.selector, abi.encode(txns))), signature);	

		// Revert if already confirmed
		require(!confirmations[nonce][signer], "Already Confirmed");	
		confirmations[nonce][signer] = true;

		emit ConfirmTransaction(msg.sender, nonce);
		executeTransaction(nonce);
	}

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param nonce Transaction Nonce.
    function revokeConfirmation(uint nonce, bytes calldata signature) public notExecuted(nonce) {
		Transaction[] memory txns = getTransaction(nonce);
		address signer = _getSigner(keccak256(abi.encodePacked(this.submitTransaction.selector, abi.encode(txns))), signature);	
        confirmations[nonce][signer] = false;

        emit RevokeConfirmation(msg.sender, nonce);
    }

	/// @dev Allows an owner or entry point to execute a confirmed transaction.
	/// @param nonce Transaction Nonce.
	function executeTransaction (uint256 nonce) public onlyOwnerOrEntryPoint notExecuted(nonce) {
		if (isConfirmed(nonce)){
			Transaction[] memory txns = transactions[nonce];
			_executeBatch(txns);
			emit ExecuteTransaction(msg.sender, nonce);
		} else {
			emit ExecuteTransactionFailure(msg.sender, nonce);
		}
	}

	/// @dev Return list of transactions of specific nonce
	/// @param nonce Transaction Nonce.
	function getTransaction(uint256 nonce) public view virtual returns (Transaction[] memory) {
		return transactions[nonce];
	}

	/// @dev Returns number of confirmations of a transaction.
	/// @param nonce Transaction Nonce.
	/// @return count of confirmations.
	function getConfirmationCount(uint256 nonce) public view virtual returns (uint256 count) {
		for (uint i=0; i<owners.length; i++)
			if (confirmations[nonce][owners[i]])
				count += 1;
	}

	/// @dev Returns the confirmation status of a transaction.
	/// @param nonce Transaction Nonce.
	/// @return Confirmation status.
	function isConfirmed(uint nonce) public view returns (bool){
		uint count = 0;
		for (uint i=0; i<owners.length; i++) {
			if (confirmations[nonce][owners[i]])
				count += 1;
			if (count == confirmationNum)
				return true;
		}
		return false;
	}

	/*
	 * Version
	 */
	function VERSION() external view virtual returns (string memory) {
		return "0.0.1";
	}
	/*
	 * Internal functions
	 */
	function _call(address target, uint256 value, bytes memory data) internal {
		(bool success, bytes memory result) = target.call{value : value}(data);
		if (!success) {
			assembly {
				revert(add(result, 32), mload(result))
			}
		}
	}

	/// @dev execute a sequence of transactions.
	/// @param txns Transactions.
	function _executeBatch(Transaction[] memory txns) internal {
		require(txns.length > 0, 'MUST_PASS_TX');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			_call(txn.to, txn.value, txn.data);
		}
	}

	/// @dev Add Transaction to the list.
	/// @param txns Transactions.
	/// @return currentNonce Current nonce.
	function _addTransaction(Transaction[] memory txns) internal returns (uint256 currentNonce) {
		currentNonce = nonce;
		for (uint256 i=0; i<txns.length; i++) {
			transactions[currentNonce].push(txns[i]);
		}
		nonce++;
		emit SubmitTransaction(msg.sender, currentNonce);
	}

	/// For supporting ERC-4337
	/// @dev validate the signature is valid for this message.
	/// @param userOp validate the userOp.signature field
	/// @param userOpHash convenient field: the hash of the request, to check the signature against
	///                   (also hashes the entrypoint and chain id)
	/// @return validationData signature and time-range of this operation
	function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
		internal
		virtual
		override
		returns (uint256 validationData)
	{
		require(msg.sender == address(_entryPoint), "Only EntryPoint");
		bytes32 hash = userOpHash.toEthSignedMessageHash();
		address signer = ECDSA.recover(hash, userOp.signature);
		if (!isOwner[signer]) {
			return SIG_VALIDATION_FAILED;
		}
		return 0;
	}

	/// @dev Get Signer address from message hash and signature
	/// @param hash message hash
	/// @param signature Signer's signature.
	function _getSigner(bytes32 hash, bytes memory signature) internal pure returns (address signer) {
		bytes32 signedHash = MessageHashUtils.toEthSignedMessageHash(hash);
		(uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);
		signer = ecrecover(signedHash, v, r, s);
	}

	/// @dev Split signature into v, r, s
	/// @param signature Signer's signature.
	function _splitSignature(bytes memory signature) private pure returns (uint8 v, bytes32 r, bytes32 s) {
		require(signature.length == 65, "Invalid signature length");

		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := byte(0, mload(add(signature, 96)))
		}
	}

	/// @dev Validate signer is one of the owner
	/// @param hash message hash
	/// @param signature Signer's signature.
	function _isValidSignature(bytes32 hash, bytes memory signature) internal view {
		require(isOwner[_getSigner(hash, signature)], "Invalid signature");
	}
}