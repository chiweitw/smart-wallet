// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Wallet.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "../UUPSProxy.sol";

// contract for creating wallets. 
contract WalletFactory {
    Wallet public immutable walletImplementation;

    constructor(IEntryPoint _entryPoint) {
        walletImplementation = new Wallet(_entryPoint);
    }

    // Create wallet
    function createWallet(address[] memory owners, uint256 confirmationNum,uint256 salt) external returns (Wallet ret) {
        address walletAddress = getAddress(owners, confirmationNum, salt);

        // If already deployed, return it.
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return Wallet(walletAddress);
        } 
        // Else deploy the new wallet.
        ret = Wallet(payable(new UUPSProxy{salt : bytes32(salt)}(
                abi.encodeCall(Wallet.initialize, (owners, confirmationNum)), //constructData 
                address(walletImplementation) //contract logic
            )));
    }

    // Get wallet address
    function getAddress(address[] memory owners, uint256 confirmationNum,uint256 salt) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(UUPSProxy).creationCode,
                    abi.encode(
                        abi.encodeCall(Wallet.initialize,(owners, confirmationNum)),  //constructData 
                        address(walletImplementation) //contract logic
                    )
                )
            )
        );
    }

}