// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/Test.sol";

import { Proxiable } from "../utils/Proxiable.sol";
import { Slots } from "../utils/Slots.sol";
import { WalletStorage } from "./WalletStorage.sol";

contract Wallet is Proxiable, Slots, WalletStorage {
  bool public initialized;

  function VERSION() external view virtual returns (string memory) {
    return "0.0.1";
  }

  function initialize(address[OWNER_LIMIT] memory _owners) external {
    require(initialized == false, "already initialized");
    require(_owners.length > 1, "owners required must grater than 1");
    require(_owners.length >= CONFIRMATION_NUM, "Num of confirmation is not sync with num of owner");
    admin = msg.sender;
    for (uint256 i=0; i < _owners.length; i++) {
      require(_owners[i]!=address(0),"Invalid Owner");
      owners.push(_owners[i]);
    }
    initialized = true;
  }

  modifier onlyAdmin {
    require(msg.sender == admin, "Only Admin");
    _; 
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
}