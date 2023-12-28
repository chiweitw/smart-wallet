// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Wallet } from "./Wallet.sol";

contract WalletV2 is Wallet {
  bool public v2Initialized;

  function VERSION() external view virtual override returns (string memory) {
    return "0.0.2";
  }
  
  function v2Initialize() external {
    require(!v2Initialized, "already initialized");
    v2Initialized = true;
  }
}