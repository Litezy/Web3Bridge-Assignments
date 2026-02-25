// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface Events {
    event StudentEvent(string _msg, uint256 indexed _studentId);
    event StudentClaimEvent(uint256 indexed studentId,uint256 indexed _amountPaid,address _wallet);
    event StaffEvent(uint256 indexed staffId, address _wallet);
    event PaidStaffEvent(uint256 indexed staffId, uint amount);
    event PropertyEvent(uint256 indexed _propertyId, string _msg);
    event PropertySold(uint256 indexed propId,address _wallet,uint256 indexed _amount);
}
