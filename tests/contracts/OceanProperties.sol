// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;
// // import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import { IERC20 } from "../interfaces/interface.sol";

// contract Oceanproperties {
//     ERC20 public token;
//     address public owner;
    
//     mapping(address => uint256) public balances;

//     constructor(address _tokenAddress) {
//         token = ERC20(_tokenAddress);
//         owner = msg.sender;
//     }

//     function etherInWei(uint256 _amount) internal pure returns (uint256) {
//         return _amount * 10 ** 18;
//     }

//     modifier onlyOwner() {
//         require(msg.sender == owner, "Not owner");
//         _;
//     }

//     modifier onlyBuyer() {
//         require(msg.sender != owner, "Only buyer can make this call");
//         _;
//     }

//     struct Property {
//         uint id;
//         uint price;
//         string propType;
//         string category;
//         address owner;
//         bool isSold;
//         bool isListed;
//         string warranty;
//     }

//     Property[] public properties;
//     uint public propertyCount = 1;
//     mapping(address => mapping(uint => Property)) public propertyDetails;

//     function createProperty(
//         uint _amount,
//         string memory _propType,
//         string memory _category,
//         string memory _warranty
//     ) external onlyOwner {
//         uint amount = etherInWei(_amount);
//         Property memory newProperty = Property(
//             propertyCount,
//             amount,
//             _propType,
//             _category,
//             msg.sender,
//             false,
//             false,
//             _warranty
//         );
//         properties.push(newProperty);
//         propertyDetails[msg.sender][propertyCount] = newProperty;
//         emit Events.PropertyEvent(propertyCount, "Property added successfully");
//         propertyCount++; 
//     }

//     function listProperty(uint _propId) external onlyOwner {
//         require(_propId < propertyCount, "Invalid property ID");
//         Property storage property = properties[_propId];
//         require(property.owner == msg.sender, "Not your property");
//         require(!property.isSold, "Property already sold");
//         require(!property.isListed, "Property already listed");

//         property.isListed = true;
//         propertyDetails[msg.sender][_propId].isListed = true;

//         emit Events.PropertyEvent(_propId, "Property listed successfully");
//     }

//     function unlistProperty(uint _propId) external onlyOwner {
//         require(_propId < propertyCount, "Invalid property ID");
//         Property storage property = properties[_propId];
//         require(property.owner == msg.sender, "Not your property");
//         require(property.isListed, "Property not listed");

//         property.isListed = false;
//         propertyDetails[msg.sender][_propId].isListed = false;

//         emit Events.PropertyEvent(_propId, "Property unlisted successfully");
//     }

//     function deleteProperty(uint _propId) external onlyOwner {
//         require(_propId < propertyCount, "Invalid property ID");
//         require(
//             properties[_propId].owner == msg.sender,
//             "Only the owner can delete this property"
//         );
//         require(!properties[_propId].isListed, "Unlist property before deleting");

//         properties[_propId] = properties[propertyCount - 1];
//         properties.pop();
//         delete propertyDetails[msg.sender][_propId];
//         propertyCount--;

//         emit Events.PropertyEvent(_propId, "Property deleted successfully");
//     }


//     function buyerApprove(uint _amount) external onlyBuyer returns (bool) {
//         require(
//             token.balanceOf(msg.sender) >= _amount,
//             "Insufficient token balance"
//         );
//         require(token.approve(address(this), _amount), "Approval failed");
//         return true;
//     }

//     function buyProperty(uint _propId) external onlyBuyer {
//         require(_propId < propertyCount, "Property not found");

//         Property storage property = properties[_propId];
//         address seller = property.owner; 

//         require(!property.isSold, "Property already sold");
//         require(property.isListed, "Property not listed");
//         require(property.owner != msg.sender, "Cannot buy your own property");
//         require(
//             token.balanceOf(msg.sender) >= property.price,
//             "Insufficient funds"
//         );
//         require(
//             token.allowance(msg.sender, address(this)) >= property.price,
//             "Approve tokens first"
//         );

//         // Update state before transfer to avioid entering again
//         property.isSold = true;
//         property.isListed = false;
//         property.owner = msg.sender;

//         // Transfer tokens from buyer to seller
//         require(
//             token.transferFrom(msg.sender, seller, property.price),
//             "Transfer failed"
//         );

//         emit Events.PropertySold(property.id, msg.sender, property.price);
//     }

//     function getAllProperties() external view returns (Property[] memory) {
//         return properties;
//     }

//     function getListedProperties() external view returns (Property[] memory) {
//         uint count = 0;
//         for (uint i = 0; i < properties.length; i++) {
//             if (properties[i].isListed) count++;
//         }
//         Property[] memory listed = new Property[](count);
//         uint index = 0;
//         for (uint i = 0; i < properties.length; i++) {
//             if (properties[i].isListed) {
//                 listed[index] = properties[i];
//                 index++;
//             }
//         }
//         return listed;
//     }

//     function getProperty(uint _propId) external view returns (Property memory) {
//         require(_propId < propertyCount, "Invalid property ID");
//         return properties[_propId];
//     }
// }