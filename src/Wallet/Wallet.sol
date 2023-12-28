// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Proxiable } from "../utils/Proxiable.sol";
import { Slots } from "../utils/Slots.sol";

contract Wallet is Proxiable, Slots {
  address public admin;
  bool public initialized;

  function VERSION() external view virtual returns (string memory) {
    return "0.0.1";
  }

  function initialize() external {
    require(initialized == false, "already initialized");
    admin = msg.sender;
    initialized = true;
  }

  modifier onlyAdmin {
    require(msg.sender == admin, "MultiSig: only admin");
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