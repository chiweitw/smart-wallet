## ERC4337 / Multi-signature Wallet

A smart crypto wallet built on smart contract technology enables powerful features such as batch transactions, multi-signature, and compatibility with ERC-4337 & Account Abstraction.

![image](https://github.com/chiweitw/smart-wallet/assets/34131145/65c75c6b-1082-44b7-b7ee-bc449e1a170f)

## Features
- Wallet & Factory
    - Manage and operate assets as a regular crypto wallet.
    - You can obtain the address either before or after the account is created, which means you can start receiving ETH or tokens before ever sending a transaction by yourself.
    - UUPS Proxy Upgradable ([ERC-1822](https://eips.ethereum.org/EIPS/eip-1822))
- Owner Manager
    - Manages admins, owners and the confirmation number.
- Multi-Signature
    - Transactions can be executed only when confirmed by a predefined `confirmationNum`.
    - Owner can revoke confirmation.
- ERC-4337 & Account Abstraction
    - Allows users to enjoy a singular account with smart contract and EOA functionality.
    - Users can send out the intent in the form of user operations and let the bundler validate and execute the operations through the entry point.
    - Based on the [Eth-Infinitism repo](https://github.com/eth-infinitism/account-abstraction).
- Batch Transaction
    - Perform multiple transaction in one single batch, improve convenience and reduce gas cost.
    - eg. Multi-Swap and Multi-Transfer. See demo in foundry test code.

## Use Cases

- Security: Manage Assets Together
    - Multi-signature increases security by requiring multiple owners to agree on transactions before execution, which is perfect for families and groups to manage important assets together.
    - Leverage with Account Abstraction. Users don't need to have ETH in their EOA account to pay for gas fees. The gas fee can be paid directly by the contract wallet, which is super fair (splitting the gas fee).
- Convenience: One-click Batch Transaction
    - With the power of batching, repeated tasks like multi-transfer/multi-swap can be conducted with only a single transaction, saving time and gas fees.
- Future and Extensibility
    - With smart contracts and account abstraction, the possibilities for the future are limited only by imagination.

## Getting started


1. Install [foundry](https://github.com/foundry-rs/foundry).

```
curl -L https://foundry.paradigm.xyz | bash
```

2. Clone the repo and build

```bash
git git@github.com:chiweitw/smart-wallet.git
cd smart-wallet
forge install
forge build
```

3. Check `.env.example` and obtain a `MAINNET_RPC_URL` from Alchemy or another service for running the Foundry test.
