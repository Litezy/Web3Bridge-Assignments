// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

interface IVault {
    function token() external view returns (address);

    function factory() external view returns (address);

    function totalDeposits() external view returns (uint256);

    function tokenNFTID() external view returns (uint256);

    function balances(address _user) external view returns (uint256);

    function getBalance(address _user) external view returns (uint256);

    function getVaultBalance() external view returns (uint256);

    function getVaultDetails()
        external
        view
        returns (
            string memory _name,
            string memory _symbol,
            uint8 _decimals,
            uint256 _mintedOn,
            address _factory,
            uint256 _token_bal
        );

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
