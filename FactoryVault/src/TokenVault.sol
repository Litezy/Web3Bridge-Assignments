// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "./interfaces/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TokenVault {
    // token this vault is dedicated to
    address public token;
    address public factory;
    uint256 public totalDeposits;
    uint256 public tokenNFTID;
    uint256 public mintedOn;

    using Strings for uint256;

    event DepositSuccessful(address indexed sender, uint256 indexed amount);
    event WithdrawalSuccessful(
        address indexed receiver,
        uint256 indexed amount
    );

    // user => balance
    mapping(address => uint256) public balances;

    modifier noZeroAddress() {
        require(msg.sender != address(0), "Address zero detected");
        _;
    }

    modifier noZeroAmount(uint256 _amount) {
        require(_amount > 0, "Amount must be greater than zero");
        _;
    }

    // constructor ties vault to one specific token
    constructor(address _token, address _factory, uint _nftID) {
        token = _token;
        factory = _factory;
        tokenNFTID = _nftID;
        mintedOn = block.timestamp;
    }

    // get individual user balance
    function getBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    // get total token held by vault
    function getVaultBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    // get vault details for NFT art
    function getVaultDetails()
        public
        view
        returns (
            string memory _name,
            string memory _symbol,
            uint8 _decimals,
            uint256 _mintedOn,
            address _factory,
            uint256 _token_bal
        )
    {
        IERC20 tokenContract = IERC20(token);
        uint256 contractBal = tokenContract.balanceOf(address(this));
        return (
            tokenContract.name(),
            tokenContract.symbol(),
            tokenContract.decimals(),
            mintedOn,
            factory,
            contractBal
        );
    }

    function deposit(uint256 amount) external noZeroAmount(amount) {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        totalDeposits += amount;

        emit DepositSuccessful(msg.sender, amount);
    }

    // withdraw token from vault
    function withdraw(
        uint256 amount
    ) external noZeroAddress noZeroAmount(amount) {
        uint256 bal = balances[msg.sender];
        require(bal >= amount, "Insufficient funds");
        require(totalDeposits >= amount, "Insufficient funds in vault");

        balances[msg.sender] -= amount;
        totalDeposits -= amount;

        IERC20(token).transfer(msg.sender, amount);

        emit WithdrawalSuccessful(msg.sender, amount);
    }

    // function needed for contract to receive an nft
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        (
            string memory _name,
            string memory _symbol,
            uint8 _decimals,
            uint256 _mintedOn,
            address _factory,
            uint256 _token_bal
        ) = getVaultDetails();

        string memory svgOutput = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                "<defs>",
                '<linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
                '<stop offset="0%" style="stop-color:#0f0c29"/>',
                '<stop offset="50%" style="stop-color:#302b63"/>',
                '<stop offset="100%" style="stop-color:#24243e"/>',
                "</linearGradient>",
                '<linearGradient id="card" x1="0%" y1="0%" x2="100%" y2="100%">',
                '<stop offset="0%" style="stop-color:#1a1a2e;stop-opacity:0.9"/>',
                '<stop offset="100%" style="stop-color:#16213e;stop-opacity:0.9"/>',
                "</linearGradient>",
                '<filter id="glow">',
                '<feGaussianBlur stdDeviation="3.5" result="coloredBlur"/>',
                '<feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>',
                "</filter>",
                "</defs>",
                // background
                '<rect width="350" height="350" fill="url(#bg)"/>',
                // card body
                '<rect x="20" y="20" width="310" height="310" rx="20" ry="20" fill="url(#card)" stroke="#6c63ff" stroke-width="1.5" opacity="0.95"/>',
                // top accent bar
                '<rect x="20" y="20" width="310" height="4" rx="2" fill="#6c63ff"/>',
                // token ID badge top right
                '<rect x="255" y="28" width="65" height="22" rx="11" fill="#6c63ff" opacity="0.2"/>',
                '<text x="287" y="43" font-size="10" font-family="monospace" text-anchor="middle" fill="#6c63ff" font-weight="bold">ID #',
                tokenId.toString(),
                "</text>",
                // lock icon circle
                '<circle cx="175" cy="78" r="28" fill="none" stroke="#6c63ff" stroke-width="2" filter="url(#glow)"/>',
                '<text x="175" y="85" font-size="22" text-anchor="middle" fill="#6c63ff" filter="url(#glow)">&#128274;</text>',
                // title
                '<text x="175" y="123" font-size="10" font-family="monospace" text-anchor="middle" fill="#6c63ff" letter-spacing="5" filter="url(#glow)">BELZIEE VAULT NFT</text>',
                // divider 1
                '<line x1="40" y1="135" x2="310" y2="135" stroke="#6c63ff" stroke-width="0.5" opacity="0.5"/>',
                // row 1 — TOKEN NAME (left) | BALANCE (right)
                '<text x="40" y="153" font-size="8" font-family="monospace" fill="#888" letter-spacing="2">TOKEN NAME</text>',
                '<text x="220" y="153" font-size="8" font-family="monospace" fill="#888" letter-spacing="2">BALANCE</text>',
                '<text x="40" y="170" font-size="13" font-family="monospace" fill="white" font-weight="bold">',
                _name,
                "</text>",
                '<text x="220" y="170" font-size="12" font-family="monospace" fill="#00ff88" font-weight="bold" filter="url(#glow)">',
                _token_bal.toString(),
                "</text>",
                // divider 2
                '<line x1="40" y1="182" x2="310" y2="182" stroke="#6c63ff" stroke-width="0.5" opacity="0.3"/>',
                // row 2 — SYMBOL (left) | DECIMALS (right)
                '<text x="40" y="198" font-size="8" font-family="monospace" fill="#888" letter-spacing="2">SYMBOL</text>',
                '<text x="220" y="198" font-size="8" font-family="monospace" fill="#888" letter-spacing="2">DECIMALS</text>',
                '<text x="40" y="215" font-size="13" font-family="monospace" fill="#6c63ff" font-weight="bold" filter="url(#glow)">',
                _symbol,
                "</text>",
                '<text x="220" y="215" font-size="13" font-family="monospace" fill="white" font-weight="bold">',
                convertToString(_decimals),
                "</text>",
                // divider 3
                '<line x1="40" y1="227" x2="310" y2="227" stroke="#6c63ff" stroke-width="0.5" opacity="0.3"/>',
                // row 3 — MINTED ON (left) | TOKEN ADDRESS (right label)
                '<text x="40" y="243" font-size="8" font-family="monospace" fill="#888" letter-spacing="2">MINTED ON</text>',
                '<text x="40" y="258" font-size="11" font-family="monospace" fill="#00ff88" font-weight="bold" filter="url(#glow)">',
                _mintedOn.toString(),
                "</text>",
                // divider 4
                '<line x1="40" y1="270" x2="310" y2="270" stroke="#6c63ff" stroke-width="0.5" opacity="0.3"/>',
                // row 4 — TOKEN ADDRESS full row
                '<text x="40" y="286" font-size="8" font-family="monospace" fill="#888" letter-spacing="2">TOKEN ADDRESS</text>',
                '<text x="40" y="300" font-size="7" font-family="monospace" fill="#aaa">',
                Strings.toHexString(uint160(token), 20),
                "</text>",
                // row 5 — FACTORY ADDRESS full row
                '<text x="40" y="316" font-size="8" font-family="monospace" fill="#888" letter-spacing="2">FACTORY</text>',
                '<text x="40" y="328" font-size="7" font-family="monospace" fill="#aaa">',
                Strings.toHexString(uint160(_factory), 20),
                "</text>",
                // corner dots
                '<circle cx="35" cy="35" r="3" fill="#6c63ff" opacity="0.5"/>',
                '<circle cx="315" cy="35" r="3" fill="#6c63ff" opacity="0.5"/>',
                '<circle cx="35" cy="315" r="3" fill="#6c63ff" opacity="0.5"/>',
                '<circle cx="315" cy="315" r="3" fill="#6c63ff" opacity="0.5"/>',
                "</svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Mainnet Forking Vault NFT #',
                        tokenId.toString(),
                        '",',
                        '"description": "OnChain NFTs attached to a vault child contract from a factory!",',
                        '"attributes": [',
                        '{"trait_type": "Token Name", "value": "',
                        _name,
                        '"},',
                        '{"trait_type": "Token Symbol", "value": "',
                        _symbol,
                        '"},',
                        '{"trait_type": "Token Decimals", "value": "',
                        convertToString(_decimals),
                        '"},',
                        '{"trait_type": "Vault Balance", "value": "',
                        _token_bal.toString(),
                        '"},',
                        '{"trait_type": "Minted On", "value": "',
                        _mintedOn.toString(),
                        '"},',
                        '{"trait_type": "Factory CA", "value": "',
                        Strings.toHexString(uint160(_factory), 20),
                        '"}',
                        "],",
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svgOutput)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function convertToString(
        uint8 value
    ) internal pure returns (string memory) {
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
}
