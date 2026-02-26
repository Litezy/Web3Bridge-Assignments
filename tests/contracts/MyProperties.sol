// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IERC20} from "../interfaces/interface.sol";
import {Events} from "../interfaces/Events.sol";

contract MyProperties {
    IERC20 public token;
    address public owner;

    mapping(address => uint256) public balances;
    mapping(string => bool) public categories;
    uint faucetAmount = 1000 * 10 ** 18;

    //errors
    error InvalidCategory(string _category);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        owner = msg.sender;
        categories["Electronics"] = true;
        categories["Interior"] = true;
        categories["Exterior"] = true;
        categories["Utensils"] = true;
        categories["Landed"] = true;
    }

    function etherInWei(uint256 _amount) internal pure returns (uint256) {
        return _amount * 10 ** 18;
    }

    modifier propertyOwner(uint _propId) {
        Property memory property = propertyDetails[_propId];
        require(msg.sender == property.owner, "Not owner of this property");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender != owner, "Only buyer can make this call");
        _;
    }

    struct Property {
        uint id;
        uint price;
        string propType;
        string category;
        address owner;
        bool isSold;
        bool isListed;
        uint8 warranty;
    }

    Property[] public properties;
    uint propertyCount;
    mapping(uint => Property) public propertyDetails;

    function createProperty(
        uint _amount,
        string memory _propType,
        string memory _category,
        uint8 _warranty
    ) external onlyOwner {
        require(categories[_category], InvalidCategory(_category));
        uint amount = etherInWei(_amount);
        Property memory newProperty = Property(
            propertyCount += 1,
            amount,
            _propType,
            _category,
            msg.sender,
            false,
            false,
            _warranty
        );
        properties.push(newProperty);
        propertyDetails[propertyCount] = newProperty;
        emit Events.PropertyEvent(propertyCount, "Property added successfully");
        propertyCount += 1;
    }

    function listProperty(uint _propId) external propertyOwner(_propId) {
        require(_propId <= propertyCount, "Invalid property ID");
        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].id == _propId) {
                require(!properties[i].isSold, "property already sold");
                require(!properties[i].isListed, "property already listed");

                properties[i].isListed = true;
                propertyDetails[_propId].isListed = true;

                emit Events.PropertyEvent(
                    _propId,
                    "property listed successfully"
                );
            }
        }
    }

    function unlistProperty(uint _propId) external propertyOwner(_propId) {
        require(_propId <= propertyCount, "Invalid property ID");
        Property storage property = propertyDetails[_propId];
        require(property.isListed, "Property not listed");
        require(!property.isSold, "Property already sold");

        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].id == _propId) {
                require(properties[i].isListed, "Property not listed");
                require(!properties[i].isSold, "Property already sold");
                properties[i].isListed = false;
                propertyDetails[_propId].isListed = false;
                break;
            }
        }
        emit Events.PropertyEvent(_propId, "Property unlisted successfully");
    }

    function deleteProperty(uint _propId) external propertyOwner(_propId) {
        require(_propId <= propertyCount, "Invalid property ID");
        Property storage property = propertyDetails[_propId];
        require(!property.isListed, "Unlist property before deleting");

        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].id == _propId) {
                require(
                    !properties[i].isListed,
                    "Unlist property before deleting"
                );
                properties[i] = properties[properties.length - 1];
                properties.pop();
                break;
            }
        }

        delete propertyDetails[_propId];
        propertyCount--;
        emit Events.PropertyEvent(_propId, "Property deleted successfully");
    }

    function claimFaucet(address _to) external {
        require(_to != address(0), "Not valid address");
        token.mint(_to, faucetAmount);
        emit Events.MintEvent(_to, faucetAmount);
    }

    function buyerApprove(uint _amount) external onlyBuyer returns (bool) {
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Insufficient token balance"
        );
        require(token.approve(address(this), _amount), "Approval failed");
        return true;
    }


    function buyProperty(uint _propId) external onlyBuyer {
    require(_propId < propertyCount, "Property not found");

    Property storage property = propertyDetails[_propId];

    require(property.owner != address(0), "Invalid property");
    require(!property.isSold, "Property already sold");
    require(property.isListed, "Property not listed");
    require(property.owner != msg.sender, "Cannot buy your own property");

    uint price = property.price;
    address seller = property.owner; 

    require(token.balanceOf(msg.sender) >= price, "Insufficient funds");
    require(
        token.allowance(msg.sender, address(this)) >= price,
        "Approve tokens first"
    );

    // 💰 INTERACTION FIRST (safe version)
    require(
        token.transferFrom(msg.sender, seller, price),
        "Transfer failed"
    );

    // 🏠 Now mutate state
    property.owner = msg.sender;
    property.isSold = true;
    property.isListed = false;

    // Optional: sync array if you insist on keeping it
    for (uint i = 0; i < properties.length; i++) {
        if (properties[i].id == _propId) {
            properties[i] = property;
            break;
        }
    }

    emit Events.PropertySold(_propId, seller, price);
}

    function getAllProperties() external view returns (Property[] memory) {
        return properties;
    }

    function getListedProperties() external view returns (Property[] memory) {
        uint count = 0;
        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].isListed) count++;
        }
        Property[] memory listed = new Property[](count);
        uint index = 0;
        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].isListed) {
                listed[index] = properties[i];
                index++;
            }
        }
        return listed;
    }

    function getProperty(uint _propId) external view returns (Property memory) {
        require(_propId <= propertyCount, "Invalid property ID");
        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].id == _propId) {
                return properties[i];
            }
        }
        revert("Property not found");
    }
}
