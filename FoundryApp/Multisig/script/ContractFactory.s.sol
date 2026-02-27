// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ContractFactory} from "../src/ContractFactory.sol";

contract ContractFactoryScript is Script {
    ContractFactory public contractInstance;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        contractInstance = new ContractFactory();

        vm.stopBroadcast();
    }
}
