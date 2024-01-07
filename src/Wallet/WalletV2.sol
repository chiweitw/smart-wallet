// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { WalletStorage } from "./WalletStorage.sol";
import { Proxiable } from "../utils/Proxiable.sol";

contract WalletV2 is WalletStorage, Proxiable {
	function VERSION() external view virtual returns (string memory) {
		return "0.0.2";
	}
}