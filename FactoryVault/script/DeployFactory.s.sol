// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.28;

// import "forge-std/Script.sol";
// import "../src/Factory.sol";

// contract DeployFactory is Script {
//     function run() external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
//         vm.startBroadcast(deployerPrivateKey);

//         Factory factory = new Factory();
//         console.log("Factory deployed to:", address(factory));



//         vm.stopBroadcast();
//     }
// }