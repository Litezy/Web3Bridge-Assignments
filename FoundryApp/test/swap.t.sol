// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test, console2} from "forge-std/Test.sol";


// contract SwapTest is Test {
//     IU uni;
//     IU l;
//     IU u;
// address usdc=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
// address lisk= 0x6033F7f88332B8db6ad452B7C6D5bB643990aE3f;
// address usdcHolder = 0x28C6c06298d514Db089934071355E5743bf21d60;
// address liskHolder= 0x20D4d2427Ee54780225afa6Ddd65Bc0B93613408;
// address router=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
// address f= 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
//     function setUp() public {
//     uni=IU(router);
//     l=IU(lisk);
//     u=IU(usdc);

//     }

// function testSwap() public{
//     vm.createSelectFork('https://0xrpc.io/eth');
// //transfer all tokens to usdcHolder
// vm.startPrank(liskHolder);
// l.transfer(usdcHolder,10000e18);

// //usdcHolder approves both tokens
// vm.startPrank(usdcHolder);
// //approve
// u.approve(router,100000e18);
// l.approve(router,100000e18);



// //create pair
// IU(f).createPair(usdc,lisk);

// //provide liquidity
// uni.addLiquidity(usdc,lisk,1000e6,5000e18,0,0,usdcHolder,block.timestamp + 9999);

// //try swapping
//     address[] memory i=new address[](2);
//     i[0]=usdc;
//     i[1]=lisk;


// uni.swapExactTokensForTokens(100e6, 0, i, address(0xbeef), block.timestamp + 7999);


// }

// interface IU {
//   function swapExactTokensForTokens(
//         uint amountIn,
//         uint amountOutMin,
//         address[] calldata path,
//         address to,
//         uint deadline
//     ) external returns (uint[] memory amounts);
//     function swapTokensForExactTokens(
//         uint amountOut,
//         uint amountInMax,
//         address[] calldata path,
//         address to,
//         uint deadline
//     ) external returns (uint[] memory amounts);
//     function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
//         external
//         payable
//         returns (uint[] memory amounts);
//     function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
//         external
//         returns (uint[] memory amounts);
//     function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
//         external
//         returns (uint[] memory amounts);
//     function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
//         external
//         payable
//         returns (uint[] memory amounts);

//         function transfer(address to , uint256 amount) external;
//         function approve(address spender,uint256 amount) external;

//           function createPair(address tokenA, address tokenB) external returns (address pair);
//               function addLiquidity(
//         address tokenA,
//         address tokenB,
//         uint amountADesired,
//         uint amountBDesired,
//         uint amountAMin,
//         uint amountBMin,
//         address to,
//         uint deadline
//     ) external returns (uint amountA, uint amountB, uint liquidity);
// }