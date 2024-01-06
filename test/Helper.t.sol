// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test, console, Vm } from "forge-std/Test.sol";
import { UUPSProxy } from "../src/UUPSProxy.sol";
import { Wallet } from "../src/Wallet/Wallet.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { WalletFactory } from "../src/Wallet/WalletFactory.sol";
import { TestERC20 } from "../src/Test/TestErc20.sol";
import { WalletStorage } from "../src/Wallet/WalletStorage.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
// import "../src/utils/UniswapV3Helper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

// interface IWETH is IERC20 {
//     /// @notice Deposit ether to get wrapped ether
//     function deposit() external payable;

//     /// @notice Withdraw wrapped ether to get ether
//     function withdraw(uint256) external;
// }

contract HelperTest is Test {
	// constants
	uint256 constant salt = 1234;
	// For test uniswap
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
	// Users
	address[] owners;
	IEntryPoint entryPoint;
	address admin;
	address alice;
	uint256 alicePrivateKey;
	address bob;
	uint256 bobPrivateKey;
	address carol;
	address someone;
	address payable beneficiary;
	address sender;
	// Proxy
	UUPSProxy proxy;
	// Factory
	WalletFactory factory;
	// Wallet
	Wallet wallet;
	uint256 confirmationNum = 2;
	// Test Token
	TestERC20 testErc20;
	uint256 initBalance = 1000 ether;
	uint256 initERC20Balance = 100e18;
	// uniswap
	// UniswapV3Helper public uni;
	ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

	function setUp() public virtual {
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpc);
		// users
		admin = makeAddr("admin");
		(alice, alicePrivateKey) = makeAddrAndKey("alice");
		(bob, bobPrivateKey) = makeAddrAndKey("bob");
		carol = makeAddr("carol");
		someone = makeAddr("someone");
		beneficiary = payable(makeAddr("beneficiary"));
		// set owners
		owners = [alice, bob, carol];
		// Deploy EntryPoint
		entryPoint = new EntryPoint();
		// Deploy Factory and Wallet
		vm.startPrank(admin);
		factory = new WalletFactory(entryPoint);
		// Create Wallet
		sender = factory.getAddress(owners, confirmationNum, salt);
		wallet = factory.createWallet(owners, confirmationNum, salt);
		// set ERC20 Token
		testErc20 = new TestERC20();
		// init balance
		deal(admin, initBalance);
		deal(alice, initBalance);
		deal(bob, initBalance);
		deal(carol, initBalance);
		deal(address(wallet), initBalance);
		// init ERC20 balance
		deal(address(testErc20), admin, initERC20Balance);
		deal(address(testErc20), alice, initERC20Balance);
		deal(address(testErc20), bob, initERC20Balance);
		deal(address(testErc20), carol, initERC20Balance);
		deal(address(testErc20), address(wallet), initERC20Balance);
		// uniswap
		// uni = new UniswapV3Helper();
		
		vm.stopPrank();
	}

	function signedInvalidMessage() internal pure returns (bytes32 message) {
		return keccak256(abi.encodePacked(Wallet.submitTransaction.selector, abi.encode("")));
	}

	// Batch Transaction for general test purpose
    function submitBatchTransaction(WalletStorage.Transaction[] memory txns, uint256 submitByKey) internal {
        wallet.submitTransaction(txns, createSignature(signedMessage(txns), submitByKey, vm));
    }

    function confirmBatchTransaction(WalletStorage.Transaction[] memory txns, uint256 confirmByKey) internal {
        wallet.confirmTransaction(0, createSignature(signedMessage(txns), confirmByKey, vm));
    }

	function signedMessage(WalletStorage.Transaction[] memory txns) internal pure returns (bytes32 message) {
		return keccak256(abi.encodePacked(Wallet.submitTransaction.selector, abi.encode(txns)));
	}

	// Multi-transfer
	function singleTransferTxns() internal view returns (WalletStorage.Transaction[] memory txns) {
		txns = new WalletStorage.Transaction[](2);
        txns[0] = WalletStorage.Transaction({
            to: bob,
            value: 0.01 ether,
            data: ""
        });
	}
	function multiTransferTxns() internal view returns (WalletStorage.Transaction[] memory txns) {
        txns = new WalletStorage.Transaction[](10);
		for (uint i = 0; i < 10; i++) {
			txns[i] = WalletStorage.Transaction({
				to: bob,
				value: 0.01 ether,
				data: ""
			});
		}
	}

	// Multi-swap
	function singleSwapTxns() internal view returns (WalletStorage.Transaction[] memory txns) {
		txns = new WalletStorage.Transaction[](10);
        txns[0] = WalletStorage.Transaction({
            to: WETH,
            value: 1 ether,
            data: abi.encodeWithSignature("deposit()")
        });
		txns[1] = WalletStorage.Transaction({
			to: WETH,
			value: 0,
			data: abi.encodeWithSignature("approve(address,uint256)", address(router), 1e18)
		});
        txns[2] = WalletStorage.Transaction({
            to: address(router),
            value: 0,
            data: abi.encodeWithSelector(router.exactInputSingle.selector, swapParams(WETH, DAI, address(wallet), 1e18))
        });
	}


	function multiSwapTxns() internal view returns (WalletStorage.Transaction[] memory txns) {
        txns = new WalletStorage.Transaction[](10);
        txns[0] = WalletStorage.Transaction({
            to: WETH,
            value: 10 ether,
            data: abi.encodeWithSignature("deposit()")
        });
		txns[1] = WalletStorage.Transaction({
			to: WETH,
			value: 0,
			data: abi.encodeWithSignature("approve(address,uint256)", address(router), 10e18)
		});
		for (uint i = 2; i < 10; i++) {
			txns[i] = WalletStorage.Transaction({
				to: address(router),
				value: 0,
				data: abi.encodeWithSelector(router.exactInputSingle.selector, swapParams(WETH, DAI, address(wallet), 1e18))
			});
		}
	}

	function swapParams(address tokenIn, address tokenOut, address recipent, uint256 amountIn) 
	internal view returns (ISwapRouter.ExactInputSingleParams memory params) {
		params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 3000,
                recipient: recipent,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
        	});
	}

	// create signature
    function createSignature(
        bytes32 messageHash,
        uint256 ownerPrivateKey,
        Vm vm
    ) public pure returns (bytes memory) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = bytes.concat(r, s, bytes1(v));
        return signature;
    }
}