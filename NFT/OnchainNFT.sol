// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyOnchainNft is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;

    constructor() ERC721("Belziee NFTS", "BLZ") Ownable(msg.sender) {}

    string[] private blockchains = [
        "Lisk",
        "Ethereum",
        "Arbitrum",
        "Optimism",
        "Base",
        "Polygon"
    ];
    string[] private dapps = [
        "Velodrome",
        "Uniswap",
        "Aave",
        "Curve",
        "Balancer"
    ];
    string[] private tokens = ["$LSK", "$ETH", "$OP", "$ARB", "$MATIC"];
    string[] private traits = ["Dark Eyes", "Blue Tongue", "Gray Hair", "Lemon Barbie", "Foodie"];

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        return sourceArray[rand % sourceArray.length];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
    string memory blockchain = getBlockchain(tokenId);
    string memory dapp = getDapp(tokenId);
    string memory token = getToken(tokenId);
    string memory trait = getTrait(tokenId);

    string memory svgOutput = string(abi.encodePacked(
    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
    '<style>.base { fill: white; font-family: serif; font-size: 14px; text-anchor: middle; }</style>',
    '<rect width="100%" height="100%" fill="#001f5b" />',
    '<text x="175" y="130" class="base">', blockchain, '</text>',
    '<text x="175" y="160" class="base">', dapp, '</text>',
    '<text x="175" y="190" class="base">', token, '</text>',
    '<text x="175" y="220" class="base">', trait, '</text>',
    '</svg>'
));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
        '{"name": "Belz Web3Bridge Card #', toString(tokenId), '",',
        '"description": "OnChain NFTs deployed on Lisk Testnet!",',
        '"attributes": [{"trait_type": "Blockchain", "value": "', blockchain, '"},',
        '{"trait_type": "Dapp", "value": "', dapp, '"},',
        '{"trait_type": "Token", "value": "', token, '"},',
        '{"trait_type": "Trait", "value": "', trait, '"}],', 
        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svgOutput)), '"}'
    ))));

    return string(abi.encodePacked("data:application/json;base64,", json));
}

    function claim(uint256 _amount) public {
        require(_amount > 0 && _amount < 6, "Amount must be between 1 and 5");
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIdCounter;
            _tokenIdCounter++;
            _safeMint(msg.sender, tokenId);
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBlockchain(
        uint256 tokenId
    ) public view returns (string memory) {
        return pluck(tokenId, "Blockchains", blockchains);
    }

    function getDapp(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Dapps", dapps);
    }

    function getToken(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Tokens", tokens);
    }

    function getTrait (uint tokenId) public  view returns ( string memory ) {
     return  pluck(tokenId, "Traits", traits);
    }

}


// CA=0xf6D54a5fe1Ef25aEf98C3ad89989256C99a0c274
