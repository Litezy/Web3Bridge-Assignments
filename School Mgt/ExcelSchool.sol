// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import "./Events.sol";
import "../IERC20.sol";

contract ExcelSchool {
    IERC20 token;
    address admin;

    mapping(uint => uint256) levelPrice;
    mapping(address => Roles) userRoles;
    mapping(address => bool) public hasClaimed;
    address  schoolTreasury = address(this);
    uint  schoolTreasuryBalance = address(this).balance;
    uint256 faucetAmount = 1000 * 10 ** 18;

    constructor(address _token) {
        admin = msg.sender;
        levelPrice[100] = 100;
        levelPrice[200] = 200;
        levelPrice[300] = 300;
        levelPrice[400] = 400;
        token = IERC20(_token);
        IERC20(_token).mint(address(this), 10000000 * 10 ** 18);
        userRoles[admin] = Roles.admin;
    }

    function claimFaucet(address _to) external {
        require(_to != address(0), "Not valid address");
        require(!hasClaimed[_to], "Already claimed tokens");
        token.mint(_to, faucetAmount);
        hasClaimed[_to] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can make this call");
        _;
    }

    enum Roles {
        admin,
        staff,
        student
    }

    enum Status {
        unpaid,
        paid
    }

    struct Staff {
        uint id;
        string name;
        address wallet;
        uint salary;
        bool paid;
        uint paidAt;
        Roles role;
        bool claimed;
        uint claimedAt;
    }

    struct Student {
        uint id;
        string name;
        address wallet;
        uint level;
        uint8 age;
        uint amountPaid;
        Status paymentStatus;
        Roles role;
        bool claimed;
        uint claimedAt;
    }

    //student modifier
    modifier onlyStudent(Roles _role) {
        require(_role == Roles.student, "Only student");
        _;
    }
    // staff modifiers
    modifier onlyStaff(Roles _role) {
        require(_role == Roles.staff, "Only staff");
        _;
    }

    //mappings
    mapping(address => Student) studentDetails;
    mapping(address => uint256) lastPaid;
    uint256 constant PAY_INTERVAL = 30 days;
    mapping(address => Staff)  staffDetails;
    // mapping(address => uint256)  schoolAccount;

    //check if paid recently modifier
    modifier checkIfStaffIsPaidRecently(address _staff_wallet) {
        require(
            staffDetails[_staff_wallet].role == Roles.staff,
            "Only staff are paid"
        );
        uint _now = block.timestamp;
        uint last = lastPaid[_staff_wallet];
        require(_now >= last + PAY_INTERVAL, "Paid recently");
        _;
    }

    //helpers
    function convertAmount(uint _amount) internal pure returns (uint256) {
        return _amount * 10 ** 18;
    }

    Staff[]  staffList;
    Student[] studentList;

    function addStudent(
        string memory _name,
        uint _level,
        uint8 _age
    ) public onlyAdmin {
        require(_level > 0 && levelPrice[_level] > 0, "Invalid Level");
        uint index = studentList.length;
        Student memory newStudent = Student({
            id: index,
            name: _name,
            wallet: address(0),
            level: _level,
            age: _age,
            amountPaid: 0,
            paymentStatus: Status.unpaid,
            role: Roles.student,
            claimed: false,
            claimedAt: 0
        });
        studentList.push(newStudent);
        emit Events.StudentEvent("student added sucessfully", newStudent.id);
    }

    function addStaff(string memory _name, uint _salary) public onlyAdmin {
        uint salary = convertAmount(_salary);
        uint _id = staffList.length;
        Staff memory newStaff = Staff({
            id: _id,
            name: _name,
            wallet: address(0),
            salary: salary,
            paid: false,
            paidAt: 0,
            role: Roles.staff,
            claimed: false,
            claimedAt: 0
        });
        staffList.push(newStaff);
        emit Events.StaffEvent(newStaff.id, newStaff.wallet);
    }

    function claimStaffId(uint _Id) external {
        require(_Id < staffList.length, "Staff not found");
        require(msg.sender != admin,"Can't be admin");
        Staff storage unClaimedStaff = staffList[_Id];

        require(!unClaimedStaff.claimed, "Already claimed");

        unClaimedStaff.wallet = msg.sender;
        unClaimedStaff.claimed = true;
        unClaimedStaff.claimedAt = block.timestamp;
        staffDetails[msg.sender];
        userRoles[msg.sender] = Roles.staff;

        emit Events.StaffEvent(_Id, unClaimedStaff.wallet);
    }


    //student claim ID
    function claimStudentId(
        uint _Id
    ) external payable onlyStudent(Roles.student) {
        require(_Id < studentList.length, "Student not found");
        require(msg.sender != admin,"Can't be admin");
        require(hasClaimed[msg.sender], "Claim tokens to pay fees");

        Student storage student = studentList[_Id];

        require(!student.claimed, "Already claimed");

        uint fee = convertAmount(levelPrice[student.level]);
        require(fee > 0, "Invalid level");

        token.transfer(address(schoolTreasury), fee);
        student.wallet = msg.sender;

        student.amountPaid = fee;

        student.claimed = true;
        student.claimedAt = block.timestamp;
        student.paymentStatus = Status.paid;
        studentDetails[student.wallet];
        userRoles[msg.sender] = Roles.student;

        emit Events.StudentClaimEvent(_Id, msg.value, student.wallet);
    }

    // pay staff
    function payStaff(
        address _wallet
    ) external onlyAdmin checkIfStaffIsPaidRecently(_wallet) {
        Staff storage _staff = staffDetails[_wallet];
        require(
            _staff.wallet != address(0),
            "Not staff/Unclaimed staff profile"
        );
        require(_staff.salary > 0, "Salary can't be 0 ether");
        require(
            schoolTreasury.balance >= _staff.salary,
            "Insufficient funds in treasury"
        );
        token.transfer(_wallet, _staff.salary);
        lastPaid[_wallet] = block.timestamp;
        _staff.paid = true;
        _staff.paidAt = block.timestamp;
        (bool success, ) = payable(_wallet).call{value: _staff.salary}("");
        require(success);
    }

    //get one student details
    function getStudent(address _wallet) public view returns (Student memory) {
        return studentDetails[_wallet];
    }

    //get one staff details
    function getStaff(address _wallet) public view returns (Staff memory) {
        return staffDetails[_wallet];
    }

    //get all staff details
    function getAllStaffDetails() public view returns (Staff[] memory) {
        return staffList;
    }

    //get all student details
    function getAllStudentDetails() public view returns (Student[] memory) {
        return studentList;
    }

    receive() external payable {}

    // BLZ token smart contract address
    // 0xE8b1f2C808892667Ac66b55C01bE559E3B15C48D
}
