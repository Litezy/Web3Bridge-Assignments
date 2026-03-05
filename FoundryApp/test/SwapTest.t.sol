// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.24;
// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import {IUniswapV2Router} from "interfaces/IUniswapV2Router.sol";
// import {IERC20} from "interfaces/IERC20.sol";

// contract SwapTest is Test {
//     IUniswapV2Router uni;
//     IERC20 usdc;
//     IERC20 lisk;
//     IUniswapV2Router factory;
//     address usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
//     address liskAddr = 0x6033F7f88332B8db6ad452B7C6D5bB643990aE3f;
//     address usdcWhale = 0x08F619716db7c6245401B543E59acAC1d25cB483;
//     address liskWhale = 0x2658723Bf70c7667De6B25F99fcce13A16D25d08;
//     address v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
//     address v2factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

//     function setUp() public {
//         uni = IUniswapV2Router(v2Router);
//         usdc = IERC20(usdcAddr);
//         lisk = IERC20(liskAddr);
//         factory = IUniswapV2Router(v2factory);
//         vm.createSelectFork(
//             "https://mainnet.infura.io/v3/9fee256c708a4eb69f6a1d380fb4c3c5"
//         );
//     }

//     function testSwap() public {
//         // create pair, add liquidity and then swap
//         // transfer tokens and create the pair

//         //check balances
//         // uint usdcBal = usdc.balanceOf(usdcWhale);
//         // uint liskBal = lisk.balanceOf(liskWhale);
//         // console.log("Balance of usdc", usdcBal);
//         // console.log("Balance of lisk", liskBal);
//         // vm.startPrank(usdcWhale);
//         // usdc.transfer(address(this), 20000e6);
//         // vm.stopPrank();

//         // vm.startPrank(liskWhale);
//         // lisk.transfer(address(this), 100000e18);
//         // vm.stopPrank();
//         // uint usdcContractBal = usdc.balanceOf(address(this));
//         // console.log("Balance of contract on usdc", usdcContractBal);
//         // uint liskContractBal = lisk.balanceOf(address(this));
//         // console.log("Balance of contract on lisk", liskContractBal);

//         // vm.startPrank(usdcWhale);
//         // usdc.approve(v2Router, 1000e6);
//         // vm.stopPrank();
//         // vm.startPrank(liskWhale);
//         // lisk.approve(v2Router, 10000e18);
//         vm.startPrank(liskWhale);
//         lisk.transfer(usdcWhale, 1000000e18); // transferring 100,000 LSK
//         vm.stopPrank();
//         vm.startPrank(usdcWhale);
//         usdc.approve(v2Router, type(uint256).max);
//         lisk.approve(v2Router, type(uint256).max);
//         uni.addLiquidity(
//             usdcAddr,
//             liskAddr,
//             90000e6,
//             1000000e18,
//             10,
//             100,
//             address(0xbeef),
//             block.timestamp + 600
//         );
//         // vm.stopPrank();
//         //

//         address fetchPair = factory.getPair(usdcAddr, liskAddr);
//         if (fetchPair == address(0)) {
//             factory.createPair(usdcAddr, liskAddr);
//             console.log("Pair created successfully?");
//         } else {
//             console.log("Pair exists");
//         }

//         //check allowances
//         // console.log(
//         //     "allowance on usdc and v2",
//         //     usdc.allowance(address(this), v2Router)
//         // );
//         // console.log(
//         //     "allowance on lisk and v2",
//         //     lisk.allowance(address(this), v2Router)
//         // );

//         // //add liquidity
//         // uni.addLiquidity(
//         //     usdcAddr,
//         //     liskAddr,
//         //     900e6,
//         //     1000e18,
//         //     10,
//         //     100,
//         //     address(0xbeef),
//         //     block.timestamp + 600
//         // );

//         vm.startPrank(usdcWhale);

//         address[] memory pairAddr = new address[](2);

//         pairAddr[0] = usdcAddr;
//         pairAddr[1] = liskAddr;
//         //approve tokens
//         IERC20(usdcAddr).approve(v2Router, 10000e6);

//         uni.swapExactTokensForTokens(
//             10000e6,
//             0,
//             pairAddr,
//             address(0xbeef),
//             block.timestamp + 600
//         );

//         vm.stopPrank();
//     }
// }
