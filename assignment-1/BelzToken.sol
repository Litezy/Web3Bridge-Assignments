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

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

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

    //transfer token
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
}
