// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "./interfaces/IVault.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract VaultNFT is ERC721URIStorage {
    uint256 public tokenIdCounter;
    address public factory;

    // tokenId => vault address
    mapping(uint256 => address) public tokenIdToVault;

    constructor() ERC721("VaultNFT", "VNFT") {
        factory = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    // accept vault address instead of uri string
    function mint(address vaultAddress) external onlyFactory returns (uint256) {
        tokenIdCounter++;
        _safeMint(vaultAddress, tokenIdCounter); // _mint skips receiver check
        tokenIdToVault[tokenIdCounter] = vaultAddress; // store vault address
        return tokenIdCounter;
    }

    // override tokenURI to read live from vault every time
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        address vaultAddress = tokenIdToVault[tokenId];
        require(vaultAddress != address(0), "Token does not exist");
        return IVault(vaultAddress).tokenURI(tokenId); // live from vault
    }
}
