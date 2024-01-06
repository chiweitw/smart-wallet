// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/utils/UniswapV3Helper.sol";



interface IWETH is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

contract UniswapV3HelperTest is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IWETH private weth = IWETH(WETH);
    IERC20 private dai = IERC20(DAI);
    IERC20 private usdc = IERC20(USDC);
    address user;
    UniswapV3Helper public uni;

    function setUp() public {
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpc);

        uni = new UniswapV3Helper();

        // user
        user = makeAddr("user");
        deal(user, 100 ether);
    }

    function testSingleHop() public {
        vm.startPrank(user);
        weth.deposit{value: 1 ether}();
        weth.approve(address(uni), 1e18);
        uint amountOut = uni.swapExactInputSingleHop(WETH, DAI, 3000, 1e18);

        console.log("DAI", amountOut);
        vm.stopPrank();

        assertGt(amountOut, 0);
    }
}