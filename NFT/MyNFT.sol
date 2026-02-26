// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin ERC721 implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {

    uint256 private _nextTokenId;

    constructor() ERC721("BelzNFT", "BLZ") Ownable(msg.sender) {}

    function mintNFT(address recipient, string memory tokenURI)public onlyOwner returns (uint256){
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }
}