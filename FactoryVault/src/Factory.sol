// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "./interfaces/IVault.sol";
import "./TokenVault.sol";
import "./VaultNFT.sol";

contract Factory {

    //events 
    event VaultCreated(address indexed token, address indexed vault);
    event NFTMinted(address indexed to, uint256 indexed tokenId, address indexed vault);

    //storage variable declarations
    mapping(address => address) public vaults;
    mapping(uint256 => address) public tokenIdToVault;

    VaultNFT public nft;

    
    constructor() {
        // initialize the nft contract, so we can have access to the mint function
        nft = new VaultNFT();
    }

    //depoying Vault function. this:
    // first of all takes it parameters for vault contract args in the constructor, this should've been dynamic but with create2, we already compute everything needed in order to get a deterministic contract address outcome.
    // so our vault needs ERC20 token Contract address of a live token, factory address and nftID which is minted on deployment and attched to the vault contract.
    function deployVault(address token) external returns (address vaultAddress) {
        require(vaults[token] == address(0), "Vault already exists for this token");

        bytes32 salt = keccak256(abi.encodePacked(token));

        // get fresh id everytime for new mint
        uint256 nextId = nft.tokenIdCounter() + 1;

        bytes memory bytecode = abi.encodePacked(
            type(TokenVault).creationCode,
            abi.encode(token, address(this), nextId)
        );

        assembly {
            vaultAddress := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
        }

        require(vaultAddress != address(0), "Vault deployment failed");
       // add the contract address alongside the ERC20 CA passed so as to keep track and prevent double vault on same token.
        vaults[token] = vaultAddress;
        // track the ID of each deployed vault for a quick lookup.
        tokenIdToVault[nextId] = vaultAddress; 

        //mint and attach an svg NFT to the vault contract address
        nft.mint(vaultAddress);

        emit VaultCreated(token, vaultAddress);
        emit NFTMinted(vaultAddress, nextId, vaultAddress); 
    }

    function computeVaultAddress(address token) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(token));

        uint256 nextId = nft.tokenIdCounter() + 1;

        bytes memory bytecode = abi.encodePacked(
            type(TokenVault).creationCode,
            abi.encode(token, address(this), nextId)
        );

        bytes32 initCodeHash = keccak256(bytecode);

        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            initCodeHash
        )))));
    }

    function getNFTAddress() external view returns (address) {
        return address(nft);
    }

    function getVault(address _token) external view returns (address) {
        return vaults[_token];
    }
}
