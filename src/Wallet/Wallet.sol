// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { WalletStorage } from "./WalletStorage.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { BaseAccount } from "account-abstraction/core/BaseAccount.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract Wallet is BaseAccount, WalletStorage {
	using ECDSA for bytes32;
	using MessageHashUtils for bytes32;

	bool public initialized;

    /*
     *  Events
     */
	event SubmitTransaction(address indexed owner, uint indexed nonce);
	event ConfirmTransaction(address indexed owner, uint indexed nonce);
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
		owners = _owners;
		for (uint256 i=0; i < _owners.length; i++) {
			require(_owners[i]!=address(0), "Invalid Owner");
			isOwner[_owners[i]] = true;
		}
		initialized = true;
		_confirmationNum = confirmationNum;
	}

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param txns Transactions.
	/// @param signature Signer's signature.
	function submitTransaction(Transaction[] memory txns, bytes calldata signature) public onlyOwnerOrEntryPoint {
		bytes32 messageHash = keccak256(abi.encode(txns));
		bytes32 signedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
		address signer = verifySignature(signedMessageHash, signature);
		uint256 nonce = _addTransaction(txns);

		confirmTransaction(nonce, signature);

		emit SubmitTransaction(msg.sender, nonce);
	}

    /// @dev Allows an owner or entry point to confirm a transaction.
    /// @param nonce Transaction Nonce.
	/// @param signature Signer's signature.
	function confirmTransaction(uint nonce, bytes calldata signature) public onlyOwnerOrEntryPoint {
		Transaction[] memory txns = getTransaction(nonce);
		bytes32 messageHash = keccak256(abi.encode(txns));
		bytes32 signedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
		address signer = verifySignature(signedMessageHash, signature);		
		confirmations[nonce][signer] = true;

		emit ConfirmTransaction(msg.sender, nonce);
		executeTransaction(nonce);
	}

    /// @dev Allows an owner or entry point to execute a confirmed transaction.
    /// @param nonce Transaction Nonce.
	function executeTransaction (uint nonce) public onlyOwnerOrEntryPoint notExecuted(nonce) {
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
    function isConfirmed(uint nonce) public returns (bool){
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[nonce][owners[i]])
                count += 1;
            if (count == _confirmationNum)
                return true;
        }
    }

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

	function _executeBatch(Transaction[] memory txns) internal {
		require(txns.length > 0, 'MUST_PASS_TX');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			_call(txn.to, txn.value, txn.data);
		}
	}
	function _addTransaction(Transaction[] memory txns) internal returns (uint256 currentNonce) {
		currentNonce = nonce;
		for (uint256 i=0; i<txns.length; i++) {
			transactions[currentNonce].push(txns[i]);
		}
		nonce++;
		emit SubmitTransaction(msg.sender, currentNonce);
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
        if (!isOwner[signer]) {
            return SIG_VALIDATION_FAILED;
        }
        return 0;
    }

    function verifySignature(bytes32 msgHash, bytes memory signature) public view returns (address signer) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);
		signer = ecrecover(msgHash, v, r, s);
    }

    function _splitSignature(bytes memory signature) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "SimpleAccount: Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}