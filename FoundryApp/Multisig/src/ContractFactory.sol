// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import './Multisig.sol';

contract ContractFactory{
    address[] childContractAddresses;

    function deployChildInstance () external {
        Multisig multisig = new Multisig();
        childContractAddresses.push(address(multisig));
    }

    function getAllContracts () external view returns (address[] memory) {
        return childContractAddresses;
    }
}
