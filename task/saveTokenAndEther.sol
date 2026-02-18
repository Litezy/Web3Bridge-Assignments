// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

// Write a smart contract that can save both ERC20 and ether for a user.

// Users must be able to:
// check individual balances,
// deposit or save in the contract.
// withdraw their savings

contract saveTokenAndEther {
    // ERC 20 token
    //events
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    string public name;
    string public symbol;
    uint256 public immutable totalSupply;
    uint8 public decimals;

    constructor() {
        name = "Belz";
        symbol = "BLZ";
        decimals = 18;
        totalSupply = 20000000000 * 10 ** 18;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint)) allowance;

    
    modifier transferFromModifier(
        uint256 _amount,
        address _from,
        address _to
    ) {
        require(_to != address(0), "Address zero detected");
        require(balanceOf[_from] >= _amount, "Insufficient funds");
        require(allowance[_from][msg.sender] >= _amount, "Allowance exceeded");
        _;
    }

    modifier approveMod(address _spender) {
        require(_spender != address(0), "Approve to zero address");
        _;
    }

    function getBalanceOf(address _wallet) public view returns (uint) {
        return balanceOf[_wallet];
    }

    

    //approve token
    function approve(
        address _spender,
        uint256 _amount
    ) public approveMod(_spender) returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    //transferFrom function
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public transferFromModifier(_amount, _from, _to) returns (bool success) {
        uint256 currentAllowance = allowance[_from][msg.sender];

        if (currentAllowance != type(uint256).max) {
            allowance[_from][msg.sender] = currentAllowance - _amount;
        }

        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    //get allowance remaining
    function getAllowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remainder) {
        return allowance[_owner][_spender];
    }

    event DepositSuccessful(
        address indexed sender,
        uint256 indexed amount,
        string _msg
    );
    event WithdrawalSuccessful(
        address indexed receiver,
        uint256 indexed amount,
        bytes data
    );

    // Ether mapping
    mapping(address => uint256) public etherBalances;

    modifier depositMod() {
        require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "Can't deposit zero value");
        _;
    }
    modifier withdrawMod() {
        require(msg.sender != address(0), "Address zero detected");
        _;
    }

    //checking individual balances on both
    function getBalanceOfErc20(address _wallet) public view returns (uint) {
        return balanceOf[_wallet];
    }

    function getEtherBalance(address _wallet) external view returns (uint) {
        return etherBalances[_wallet];
    }


    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    //deposit or save in the contract for both erc20 and ether
    function depositEther() external payable depositMod {
        etherBalances[msg.sender] = etherBalances[msg.sender] + msg.value;
        emit DepositSuccessful(msg.sender, msg.value, "ether");
    }

    function depositErc20(uint _amount) external payable depositMod {
        balanceOf[msg.sender] = balanceOf[msg.sender] + _amount;
        emit DepositSuccessful(msg.sender, msg.value, "erc 20");
    }

    //withdraw savings
    function withdrawEther(uint256 _amount) external withdrawMod {
        uint256 userSavings_ = etherBalances[msg.sender];

        require(userSavings_ > 0, "Insufficient funds");

        etherBalances[msg.sender] = userSavings_ - _amount;

        // (bool result,) = msg.sender.call{value: msg.value}("");
        (bool result, bytes memory data) = payable(msg.sender).call{
            value: _amount
        }("");

        require(result, "transfer failed");

        emit WithdrawalSuccessful(msg.sender, _amount, data);
    }

    function withdrawErc20(uint256 _amount) external withdrawMod {
        uint256 userSavings_ = balanceOf[msg.sender];
        require(userSavings_ > _amount, "Insufficient funds");
        balanceOf[msg.sender] = userSavings_ - _amount;

        // (bool result,) = msg.sender.call{value: msg.value}("");
        (bool result, bytes memory data) = payable(msg.sender).call{
            value: _amount
        }("");

        require(result, "transfer failed");

        emit WithdrawalSuccessful(msg.sender, _amount, data);
    }
}
