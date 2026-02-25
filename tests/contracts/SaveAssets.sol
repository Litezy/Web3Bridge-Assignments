// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import {IERC20} from "../interfaces/interface.sol";

// Write a smart contract that can save both ERC20 and ether for a user.

// Users must be able to:
// check individual balances,
// deposit or save in the contract.
// withdraw their savings

contract SaveAssets {
    IERC20 token;
    //events
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event DepositSuccessful(address indexed sender,uint256 indexed amount,string _msg);
    event WithdrawalSuccessful(address indexed receiver,uint256 indexed amount,bytes data);

    mapping(address => mapping(address => uint256)) public erc20Balances;

    // Ether mapping
    mapping(address => uint256) public etherBalances;

    modifier depositMod() {
        require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "Can't deposit zero value");
        _;
    }
    modifier withdrawMod(uint _amount) {
        require(msg.sender != address(0), "Address zero detected");
        require(address(this).balance >= _amount, "Contract lacks ETH");
        _;
    }

    constructor (address _token){
         token = IERC20(_token);
    }

    //checking individual balances on both

    function getEtherBalance(address _wallet) external view returns (uint) {
        return etherBalances[_wallet];
    }

    function getContractBalanceInEther() external view returns (uint256) {
        return address(this).balance;
    }

    //deposit or save in the contract for both erc20 and ether
    function depositEther() external payable depositMod {
        etherBalances[msg.sender] = etherBalances[msg.sender] + msg.value;
        emit DepositSuccessful(msg.sender, msg.value, "ether");
    }

    function depositErc20(address _token, uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        token.transferFrom(msg.sender, address(this), amount);
        erc20Balances[msg.sender][_token] += amount;
        emit DepositSuccessful(msg.sender, msg.value, "erc 20");
    }

    //withdraw savings
    function withdrawEther(uint256 _amount) external withdrawMod(_amount) {
        uint256 userSavings_ = etherBalances[msg.sender];

        require(userSavings_ >= _amount, "Insufficient funds");

        etherBalances[msg.sender] = userSavings_ - _amount;
        //send funds to user
        (bool result, bytes memory data) = payable(msg.sender).call{
            value: _amount
        }("");
        require(result, "transfer failed");

        emit WithdrawalSuccessful(msg.sender, _amount, data);
    }

    function withdrawErc20(
        address _token,
        uint256 amount
    ) external returns (bool success) {
        uint256 bal = erc20Balances[msg.sender][_token];

        require(bal >= amount, "Insufficient funds");

        erc20Balances[msg.sender][_token] -= amount;

        token.transfer(msg.sender, amount);

        return true;
    }

    receive() external payable {}

    fallback() external payable {}
}
