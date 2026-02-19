// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

contract BelzToken {
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;
    address public owner;

    constructor() {
        name = "Belz";
        symbol = "BLZ";
        decimals = 18;
        totalSupply = 200000 * 10 ** decimals;
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier transferModifier(uint256 _amount, address _to) {
        require(_to != msg.sender, "Self transfer");
        require(_to != address(0), "Address zero detected");
        require(_amount > 0, "Zero transfer");
        require(balanceOf[msg.sender] >= _amount, "Insufficient funds");
        _;
    }

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

    //transfer token
    //Transfer lets us transfer value from address of the caller to the _to address
    function transfer(
        address _to,
        uint256 _amount
    ) public transferModifier(_amount, _to) returns (bool) {
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
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

    // Mint function - creates new tokens and adds to total supply
    function mint(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0), "Mint to zero address");
        require(_amount > 0, "Mint amount must be greater than zero");

        totalSupply += _amount;
        balanceOf[_to] += _amount;
        
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    // Burn function - destroys tokens from caller's balance
    function burn(uint256 _amount) public returns (bool) {
        require(_amount > 0, "Burn amount must be greater than zero");
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance to burn");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    // BurnFrom function - destroys tokens from another address (requires approval)
    function burnFrom(address _from, uint256 _amount) public returns (bool) {
        require(_from != address(0), "Burn from zero address");
        require(_amount > 0, "Burn amount must be greater than zero");
        require(balanceOf[_from] >= _amount, "Insufficient balance to burn");
        require(allowance[_from][msg.sender] >= _amount, "Burn amount exceeds allowance");

        uint256 currentAllowance = allowance[_from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            allowance[_from][msg.sender] = currentAllowance - _amount;
        }

        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    // Transfer ownership function
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        owner = newOwner;
    }
}