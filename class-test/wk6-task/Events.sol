// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
 
 interface Events {
    event PropertyEvent(uint256 indexed _propertyId,string _msg);
    event PropertySold(uint256 indexed propId,address _wallet, uint256 indexed _amount);
}