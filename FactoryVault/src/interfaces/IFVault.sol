// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IFVault {
    function deployVault(address token) external returns (address);

    function computeVaultAddress(address token) external view returns (address);

    function getNFTAddress() external view returns (address);

    function getVault(address token) external view returns (address); 
}
