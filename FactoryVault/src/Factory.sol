// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "./interfaces/IVault.sol";
import "./TokenVault.sol";
import "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./VaultNFT.sol";

contract Factory {
    using Strings for uint256;
    using Strings for uint8;

    mapping(address => address) public vaults;
    mapping(uint256 => address) public tokenIdToVault;

    VaultNFT public nft;

    event VaultCreated(address indexed token, address indexed vault);
    event NFTMinted(address indexed to, uint256 indexed tokenId, address indexed vault);

    constructor() {
        nft = new VaultNFT();
    }

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

        vaults[token] = vaultAddress;
        tokenIdToVault[nextId] = vaultAddress; 

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
