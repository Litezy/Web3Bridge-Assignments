// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address _to, uint256 _amount) external;
}

contract Multisig {
    event Transfer(address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event TxnApprovedBySigner(address _signer, uint256 _txnId);
    event SignerChanged(address _newSigner, address _oldSigner, uint _time);
    event OwnerChanged(address _newSigner, address _oldSigner, uint _time);
    event TransactionApproved(
        address[] _owners,
        uint256 indexed _amount,
        uint256 _transactionId
    );
    IERC20 public token;
    event SignersAdded(string _msg, address[] _Owners);
    event FundsWithdrawn(address _to, uint256 _amount);
    event DepositSuccessful(string _msg, uint value, address indexed wallet);
    event SignerRemoved(string _msg, address[] _Owners);

    event TransactionCreated(
        string _msg,
        address _creator,
        uint256 _transactionId,
        address _to
    );

    //enums
    enum TxnStatus {
        pending,
        successful,
        canceled
    }

    address private owner;
    address[] public signers;
    uint256 private threshold;
    uint256 private maxSigners = 5;
    uint private transactionId = 1;

    struct Transaction {
        uint256 id;
        address to;
        uint256 amount;
        uint256 approvals;
        bool initiatorApproved;
        bytes data;
        bool executed;
        TxnStatus status;
        address txnInitiator;
        uint executedTime;
    }

    struct Signer {
        address signerAddress;
        uint txnId;
        uint timeSigned;
    }

    Signer[] public txnSigners;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public approvals;
    mapping(address => bool) public isSigner;

    mapping(address => uint256) etherBalances;

    //errors
    error NotAValidSigner();
    error MaxSignersLimitExceeded();
    error InvalidTransactionID();
    error InvalidTransactionInitiator();
    error TransactionFailed();
    error TransactionAlreadyExecuted();
    error TxnApprovalsNotUpToThreshHold();
    error TransactionIDNotFound();
    error NotInitiator();
    error InsufficientFundsInContract();
    error TransactionAlreadyApprovedByYou();
    error NotOwner();
    error TxnInitiatorMustApprove();
    error TransactionAlreadyCancelled();
    error NotASigner();
    error NotAContractCall();
    error ZeroAddressNotAllowed();
    error TransferFailed();

    modifier onlyValidSigner() {
        if (isSigner[msg.sender] == false) revert NotAValidSigner();
        _;
    }

    function checkId(uint _txnId) private view returns (bool) {
        if (_txnId == 0 || _txnId >= transactionId)
            revert InvalidTransactionID();
        return true;
    }

    modifier approvedTxnId(uint _txnId) {
        checkId(_txnId);
        Transaction memory transaction = transactions[_txnId];
        if (transaction.id != _txnId) revert InvalidTransactionID();
        if (transaction.executed == true) revert TransactionAlreadyExecuted();
        if (transaction.status == TxnStatus.canceled)
            revert TransactionAlreadyCancelled();
        if (transaction.approvals < threshold)
            revert TxnApprovalsNotUpToThreshHold();
        _;
    }

    modifier onlyInitiator(uint _txnId) {
        checkId(_txnId);
        Transaction memory transaction = transactions[_txnId];
        if (transaction.txnInitiator != msg.sender) revert NotInitiator();
        if (msg.sender.code.length != 0) revert NotAContractCall();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address[] memory _addresses, address _token) {
        for (uint8 i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == address(0)) revert ZeroAddressNotAllowed();
            if (_addresses.length > maxSigners) revert MaxSignersLimitExceeded();
            signers.push(_addresses[i]);
            isSigner[_addresses[i]] = true;
        }
        emit SignersAdded("owner's populated successfully", signers);
        threshold = (_addresses.length * 60 + 99) / 100;
        if (threshold == 0) threshold = 1; // safety net if signers < 2
        token = IERC20(_token);
        token.mint(address(this), 10000000e18);
        owner = msg.sender;
    }

    function createATransaction(
        address _to,
        uint _amount
    ) public onlyValidSigner {
        transactions[transactionId] = Transaction(
            transactionId,
            _to,
            _amount,
            0,
            false,
            "",
            false,
            TxnStatus.pending,
            msg.sender,
            0
        );
        emit TransactionCreated(
            "Transaction created successfully",
            msg.sender,
            _amount,
            _to
        );
        transactionId++;
    }

    function approveTxnWithId(uint _txnId) external onlyInitiator(_txnId) {
        Transaction storage transaction = transactions[_txnId];
        if (transaction.txnInitiator != msg.sender)
            revert InvalidTransactionInitiator();
        if (transaction.status == TxnStatus.successful)
            revert TransactionAlreadyExecuted();
        if (transaction.status == TxnStatus.canceled)
            revert TransactionAlreadyCancelled();
        //update state
        transaction.initiatorApproved = true;
        approvals[_txnId][msg.sender] = true;
        emit Approval(msg.sender, address(this), transaction.amount);
    }

    function getOneTransaction(
        uint _txnId
    ) public view returns (Transaction memory) {
        checkId(_txnId);
        return transactions[_txnId];
    }

    function withdrawTokens(address _to, uint _amount) internal {
        if (token.balanceOf(address(this)) < _amount)
            revert InsufficientFundsInContract();
        bool success = token.transfer(_to, _amount);
        if (!success) revert TransferFailed();
        emit Transfer(_to, _amount);
    }

    function approveTransaction(uint _txnId) public onlyValidSigner {
        if (approvals[_txnId][msg.sender] == true)
            revert TransactionAlreadyApprovedByYou();

        Transaction storage txn = transactions[_txnId];

        if (!txn.initiatorApproved) revert TxnInitiatorMustApprove();

        txn.approvals += 1;

        approvals[_txnId][msg.sender] = true;

        txnSigners.push(Signer(msg.sender, _txnId, block.timestamp));

        emit TxnApprovedBySigner(msg.sender, _txnId);

        if (txn.approvals >= threshold && !txn.executed) {
            txn.executed = true;

            txn.status = TxnStatus.successful;

            txn.executedTime = block.timestamp;

            withdrawTokens(txn.to, txn.amount);

            emit TransactionApproved(signers, txn.amount, txn.id);
        }
    }

    function getSignersOfATxn(
        uint _txnId
    ) public view returns (Signer[] memory) {
        checkId(_txnId);
        uint256 count;
        for (uint256 i = 0; i < txnSigners.length; i++) {
            if (txnSigners[i].txnId == _txnId) {
                count++;
            }
        }
        Signer[] memory txList = new Signer[](count);
        uint8 index = 0;
        for (uint8 i = 0; i < txnSigners.length; i++) {
            if (txnSigners[i].txnId == _txnId) {
                txList[index] = txnSigners[i];
                index++;
            }
        }
        return txList;
    }

    function cancelTxn(uint _txnId) public onlyInitiator(_txnId) {
        Transaction storage txn = transactions[_txnId];
        if (txn.executed) revert TransactionAlreadyExecuted();
        if (txn.status == TxnStatus.canceled)
            revert TransactionAlreadyCancelled();
        txn.status = TxnStatus.canceled;
    }

    function changeSigner(
        address _oldSigner,
        address _newSigner
    ) external onlyOwner {
        if (!isSigner[_oldSigner]) revert NotASigner();
        if (_newSigner == address(0)) revert ZeroAddressNotAllowed();
        delete isSigner[_oldSigner];
        isSigner[_newSigner] = true;
        // update signers array too
        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == _oldSigner) {
                signers[i] = _newSigner;
                break;
            }
        }
        emit SignerChanged(_newSigner, _oldSigner, block.timestamp);
    }

    function changeOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert ZeroAddressNotAllowed();
        owner = _newOwner;
        emit OwnerChanged(_newOwner, msg.sender, block.timestamp);
    }
}
