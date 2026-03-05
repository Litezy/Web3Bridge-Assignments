// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NumberFactory, NumberChildren} from "src/NumberFactory.sol";

contract NumberFactoryTest is Test {
    NumberFactory nfactory;

    function setUp() public {
        vm.prank(address(0xdead), address(0xdead));

        bytes memory bytecode = type(NumberFactory).creationCode;
        address deployed;

        assembly {
            deployed := create(
                0, // ETH value to send
                add(bytecode, 0x20), // skip the 32-byte length prefix
                mload(bytecode) // bytecode length
            )
        }
        require(deployed != address(0), "Deploy failed");
        nfactory = NumberFactory(deployed);
        console2.log("Contract address", address(nfactory));
        console2.logBytes(type(NumberFactory).creationCode);
    }

    // function setUp() public {
    //     vm.prank(address(0xdead), address(0xdead));
    //     nfactory = new NumberFactory();
    //     console2.log("Contract address",address(nfactory));
    //     console2.logBytes(type(NumberFactory).creationCode);
    // }

    function testChildDep() external {
        vm.prank(address(0xdead), address(0xdead));
        nfactory.registerNumber(123456);
    }
}
