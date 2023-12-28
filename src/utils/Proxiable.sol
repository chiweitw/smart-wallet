// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// interface Proxiable {
//   function proxiableUUID() external pure returns (bytes32);
// }
contract Proxiable {
    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(keccak256("PROXIABLE"));
    }
}