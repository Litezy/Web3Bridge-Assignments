// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// Here's the full lifecycle:

// Deploy multisig
// Set owners
// Set threshold
// Owner submits transaction
// Stored as pending
// Other owners approve
// Approvals accumulate
// Once approvals ≥ threshold
// Anyone can execute
// Funds move / call executes

contract Multisig {
    event OwnerAdded(string _msg, address _Owner);
    event FundsWithdrawn(address _to, uint256 _amount);
    event TransactionCreated(
        string _msg,
        address _creator,
        uint256 _transactionId,
        address _to
    );
    event DepositSuccessful(string _msg, uint value, address indexed wallet);

    address[] public owners;
    uint256 public threshold = 3;
    uint256 public maxOwners = 5;
    uint256 public nextTxId;
    struct Transaction {
        uint256 id;
        address to;
        uint256 value;
        uint256 approvals;
        bytes data;
        bool executed;
        uint executedTime;
    }
    uint private transactionId = 1;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public approvals;
    mapping(address => bool) public isOwner;

    mapping(address => uint256) etherBalances;

    constructor() {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
        emit OwnerAdded("first owner added successfully", msg.sender);
    }

    function makeOwner() public {
        require(msg.sender != address(0), "Address zero detected");
        require(!isOwner[msg.sender], "Owner already exists");
        require(
            owners.length <= maxOwners,
            "Owners are filled, no room for more"
        );
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
        emit OwnerAdded("owner added successfully", msg.sender);
    }

    function createATransaction(address _to, uint _amount) public {
        require(owners.length != maxOwners, "Owners are not filled yet");
        // Transaction storage pendingTransaction = transactions[transactionId];
        // require(,"Approve the last pending transaction");
        require(isOwner[msg.sender], "Only owner can create a transaction");
        transactions[transactionId] = Transaction(
            transactionId,
            _to,
            _amount,
            1,
            "",
            false,
            0
        );
        emit TransactionCreated(
            "Transaction created successfully",
            msg.sender,
            _amount,
            _to
        );
        approvals[transactionId][msg.sender] = true;
        transactionId++;
    }

    function depositEther() external payable {
        require(isOwner[msg.sender], "Only owner can deposit");
        etherBalances[address(this)] = etherBalances[address(this)] + msg.value;
        emit DepositSuccessful("deposited successfully", msg.value, msg.sender);
    }

    function getOneTransaction(uint Id) public view returns (Transaction memory) {
        require(Id < transactionId, "Invalid Transaction Id");
        return transactions[Id];
    }

    function withdrawEther(
        address _to,
        uint256 _amount,
        uint _transactionId
    ) internal {
        uint256 ownerSavings_ = etherBalances[address(this)];
        require(ownerSavings_ >= _amount, "Insufficient funds");

        etherBalances[msg.sender] = ownerSavings_ - _amount;

        Transaction storage transaction = transactions[_transactionId];
        (bool result, bytes memory data) = payable(_to).call{value: _amount}("");
        require(result, "transfer failed");
        transaction.data = data;
    }

    function approveTransaction(uint Id) public {
        require(Id <= transactionId, "Invalid Transaction Id");
        require(
            approvals[Id][msg.sender] == false,
            "You have already approved this transaction"
        );
        Transaction storage transaction = transactions[Id];
        require(transaction.executed == false, "Transaction already executed");
        transaction.approvals++;
        approvals[Id][msg.sender] = true;
        if (transaction.approvals >= threshold && !transaction.executed) {
            transaction.executed = true;
            transaction.executedTime = block.timestamp;
            withdrawEther(transaction.to,transaction.value,transaction.id);
        }
    }
}
